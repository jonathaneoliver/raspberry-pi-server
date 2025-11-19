from fastapi import FastAPI, HTTPException, status
from fastapi.responses import JSONResponse
from typing import Optional, List
import os
import psycopg2
from psycopg2.extras import RealDictCursor
import redis
from datetime import datetime
import json

app = FastAPI(
    title="Python FastAPI App",
    description="Sample Python application for Raspberry Pi deployment",
    version="1.0.0",
)


# Database connection
def get_db_connection():
    try:
        conn = psycopg2.connect(
            os.getenv("DATABASE_URL"), cursor_factory=RealDictCursor
        )
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        raise


# Redis connection
try:
    redis_client = redis.from_url(os.getenv("REDIS_URL"), decode_responses=True)
    redis_client.ping()
    print("✅ Connected to Redis")
except Exception as e:
    print(f"❌ Redis connection error: {e}")
    redis_client = None

# Test database connection
try:
    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute("SELECT NOW()")
        result = cur.fetchone()
        print(f"✅ Connected to PostgreSQL at {result['now']}")
    conn.close()
except Exception as e:
    print(f"❌ Database connection error: {e}")


@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Welcome to Python FastAPI App on Raspberry Pi!",
        "docs": "/docs",
        "endpoints": {
            "health": "/health",
            "users": "/users",
            "posts": "/posts",
            "cache": "/cache/{key}",
            "stats": "/stats",
        },
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "python-app",
        "timestamp": datetime.now().isoformat(),
    }


@app.get("/users")
async def get_users():
    """Get all users (with caching)"""
    try:
        # Try cache first
        if redis_client:
            cached = redis_client.get("users:all")
            if cached:
                print("📦 Cache hit for users")
                return {"source": "cache", "data": json.loads(cached)}

        # Get from database
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM users ORDER BY created_at DESC")
            users = cur.fetchall()
        conn.close()

        # Cache the result
        if redis_client:
            redis_client.setex("users:all", 60, json.dumps(users, default=str))

        return {"source": "database", "data": users}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch users: {str(e)}")


@app.get("/users/{user_id}")
async def get_user(user_id: int):
    """Get user by ID"""
    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
            user = cur.fetchone()
        conn.close()

        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        return user
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch user: {str(e)}")


@app.post("/users", status_code=status.HTTP_201_CREATED)
async def create_user(username: str, email: str):
    """Create a new user"""
    try:
        if not username or not email:
            raise HTTPException(status_code=400, detail="Username and email required")

        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO users (username, email) VALUES (%s, %s) RETURNING *",
                (username, email),
            )
            user = cur.fetchone()
            conn.commit()
        conn.close()

        # Invalidate cache
        if redis_client:
            redis_client.delete("users:all")

        return user
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create user: {str(e)}")


@app.get("/posts")
async def get_posts():
    """Get all posts with user information"""
    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("""
                SELECT p.*, u.username, u.email 
                FROM posts p 
                JOIN users u ON p.user_id = u.id 
                ORDER BY p.created_at DESC
            """)
            posts = cur.fetchall()
        conn.close()

        return posts
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch posts: {str(e)}")


@app.post("/posts", status_code=status.HTTP_201_CREATED)
async def create_post(user_id: int, title: str, content: Optional[str] = None):
    """Create a new post"""
    try:
        if not title:
            raise HTTPException(status_code=400, detail="Title required")

        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO posts (user_id, title, content) VALUES (%s, %s, %s) RETURNING *",
                (user_id, title, content),
            )
            post = cur.fetchone()
            conn.commit()
        conn.close()

        return post
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create post: {str(e)}")


@app.get("/cache/{key}")
async def get_cache(key: str):
    """Get value from cache"""
    try:
        if not redis_client:
            raise HTTPException(status_code=503, detail="Redis not available")

        value = redis_client.get(key)

        if value is None:
            raise HTTPException(status_code=404, detail="Key not found")

        return {"key": key, "value": value}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get cache: {str(e)}")


@app.post("/cache/{key}")
async def set_cache(key: str, value: str, ttl: Optional[int] = None):
    """Set value in cache"""
    try:
        if not redis_client:
            raise HTTPException(status_code=503, detail="Redis not available")

        if ttl:
            redis_client.setex(key, ttl, value)
        else:
            redis_client.set(key, value)

        return {"key": key, "value": value, "ttl": ttl or "no expiry"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to set cache: {str(e)}")


@app.get("/stats")
async def get_stats():
    """Get application statistics"""
    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) as count FROM users")
            user_count = cur.fetchone()["count"]

            cur.execute("SELECT COUNT(*) as count FROM posts")
            post_count = cur.fetchone()["count"]
        conn.close()

        return {
            "users": user_count,
            "posts": post_count,
            "redis_connected": redis_client is not None and redis_client.ping(),
            "database_connected": True,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch stats: {str(e)}")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
