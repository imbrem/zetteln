use axum::{Router, extract::State, response::Json, routing::get};
use mysql_async::{OptsBuilder, Pool, prelude::*};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::info;

const VERSION: &str = env!("CARGO_PKG_VERSION");

#[derive(Clone)]
struct AppState {
    db: Pool,
}

#[derive(Serialize, Deserialize)]
struct VersionResponse {
    version: String,
    database: String,
}

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    // install global subscriber configured based on RUST_LOG envvar.
    tracing_subscriber::fmt::init();
    info!("Initializing zetteln server v{VERSION}");

    // Connect to Dolt via UNIX socket (without specifying database initially)
    let socket_path = std::env::var("DATABASE_SOCKET")
        .unwrap_or_else(|_| "/var/run/mysqld/mysqld.sock".to_string());

    info!("Connecting to Dolt via socket: {}", socket_path);

    let opts = OptsBuilder::default()
        .socket(Some(socket_path.clone()))
        .user(Some("root"));

    let init_pool = Pool::new(opts);

    // Initialize database
    let mut conn = init_pool.get_conn().await?;

    // Get version
    let version: String = conn.query_first("SELECT @@version").await?.unwrap();
    info!("Connected to Dolt version: {}", version);

    // Create database if it doesn't exist
    conn.query_drop("CREATE DATABASE IF NOT EXISTS zetteln")
        .await?;
    conn.query_drop("USE zetteln").await?;

    // Initialize schema
    info!("Initializing database schema...");
    conn.query_drop(
        r#"
        CREATE TABLE IF NOT EXISTS notes (
            id VARCHAR(36) PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            content TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    "#,
    )
    .await?;

    // Insert demo data if table is empty
    let count: Option<i64> = conn.query_first("SELECT COUNT(*) FROM notes").await?;
    if count == Some(0) {
        info!("Inserting demo data...");
        conn.query_drop(r#"
            INSERT INTO notes (id, title, content) VALUES 
                ('demo-1', 'Welcome to Zetteln', 'This is your first note in the zettelkasten system!')
        "#).await?;
    }

    info!("Database initialization complete");
    drop(conn);

    // Now create pool with database specified for application use
    let app_opts = OptsBuilder::default()
        .socket(Some(socket_path))
        .user(Some("root"))
        .db_name(Some("zetteln"));

    let app_pool = Pool::new(app_opts);

    let state = Arc::new(AppState { db: app_pool });

    // Build our application with a route
    let app = Router::new()
        .route("/api/version", get(get_version))
        .with_state(state);

    // Run the server
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await?;

    info!("Listening on http://0.0.0.0:8080");

    axum::serve(listener, app).await?;

    Ok(())
}

async fn get_version(State(state): State<Arc<AppState>>) -> Result<Json<VersionResponse>, String> {
    let mut conn = state.db.get_conn().await.map_err(|e| e.to_string())?;

    let db_version: String = conn
        .query_first("SELECT @@version")
        .await
        .map_err(|e| e.to_string())?
        .ok_or("No version returned")?;

    Ok(Json(VersionResponse {
        version: VERSION.to_string(),
        database: db_version,
    }))
}
