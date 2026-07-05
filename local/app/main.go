package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/ssm"
	_ "github.com/lib/pq"
	"github.com/redis/go-redis/v9"
)

type Config struct {
	Port         string
	DBHost       string
	DBPort       string
	DBUser       string
	DBPassword   string
	DBName       string
	RedisHost    string
	RedisPort    string
	AWSEndpoint  string
	AWSRegion    string
	BucketName   string
	SsmParamPath string
}

var (
	appConfig   Config
	dbClient    *sql.DB
	redisClient *redis.Client
	awsCfg      aws.Config
)

func main() {
	log.Println("Starting integration application...")

	// Load configuration
	appConfig = Config{
		Port:         getEnv("PORT", "8080"),
		DBHost:       getEnv("DB_HOST", "postgres"),
		DBPort:       getEnv("DB_PORT", "5432"),
		DBUser:       getEnv("DB_USER", "app"),
		DBPassword:   getEnv("DB_PASSWORD", "app"),
		DBName:       getEnv("DB_NAME", "app"),
		RedisHost:    getEnv("REDIS_HOST", "redis"),
		RedisPort:    getEnv("REDIS_PORT", "6379"),
		AWSEndpoint:  getEnv("AWS_ENDPOINT_URL", "http://localstack:4566"),
		AWSRegion:    getEnv("AWS_REGION", "us-east-1"),
		BucketName:   getEnv("S3_BUCKET_NAME", "sample-app-bucket"),
		SsmParamPath: getEnv("SSM_PARAMETER_PATH", "/dev/sample-app/ecs_cluster_name"),
	}

	// Initialize database with retries
	var err error
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		appConfig.DBHost, appConfig.DBPort, appConfig.DBUser, appConfig.DBPassword, appConfig.DBName)
	
	for i := 0; i < 5; i++ {
		dbClient, err = sql.Open("postgres", dsn)
		if err == nil {
			err = dbClient.Ping()
			if err == nil {
				log.Println("Successfully connected to PostgreSQL database")
				break
			}
		}
		log.Printf("Waiting for PostgreSQL database (attempt %d/5): %v", i+1, err)
		time.Sleep(3 * time.Second)
	}

	// Initialize Redis
	redisClient = redis.NewClient(&redis.Options{
		Addr: fmt.Sprintf("%s:%s", appConfig.RedisHost, appConfig.RedisPort),
	})
	log.Println("Redis client initialized")

	// Initialize AWS Config for LocalStack
	customResolver := aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
		return aws.Endpoint{
			URL:           appConfig.AWSEndpoint,
			SigningRegion: appConfig.AWSRegion,
		}, nil
	})

	awsCfg, err = config.LoadDefaultConfig(context.TODO(),
		config.WithRegion(appConfig.AWSRegion),
		config.WithEndpointResolverWithOptions(customResolver),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider("dummy", "dummy", "")),
	)
	if err != nil {
		log.Fatalf("Unable to load AWS config: %v", err)
	}
	log.Println("AWS LocalStack client initialized")

	// Set up database schema
	setupDatabaseSchema()

	// Define HTTP handlers
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/hits", hitsHandler)
	http.HandleFunc("/aws-check", awsCheckHandler)
	http.HandleFunc("/db-test", dbTestHandler)
	http.HandleFunc("/", rootHandler)

	log.Printf("Server listening on port %s", appConfig.Port)
	if err := http.ListenAndServe(":"+appConfig.Port, nil); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}

func setupDatabaseSchema() {
	if dbClient == nil {
		return
	}
	query := `
	CREATE TABLE IF NOT EXISTS audit_logs (
		id SERIAL PRIMARY KEY,
		action VARCHAR(255) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);`
	_, err := dbClient.Exec(query)
	if err != nil {
		log.Printf("Failed to create schema: %v", err)
	} else {
		log.Println("Schema initialized in PostgreSQL")
	}
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := map[string]interface{}{
		"status":      "online",
		"message":     "Developer Experience Integration App is running",
		"timestamp":   time.Now().Format(time.RFC3339),
		"environment": os.Getenv("ENV_NAME"),
		"endpoints": []string{
			"GET /health     - Checks connection status of PG, Redis, and AWS",
			"GET /hits       - Increments and returns request count from Redis",
			"GET /db-test    - Writes a log entry and reads from PostgreSQL",
			"GET /aws-check  - Fetches configuration parameter and lists objects in S3",
		},
	}
	json.NewEncoder(w).Encode(response)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	dbStatus := "healthy"
	if dbClient == nil {
		dbStatus = "uninitialized"
	} else if err := dbClient.Ping(); err != nil {
		dbStatus = fmt.Sprintf("unhealthy: %v", err)
	}

	redisStatus := "healthy"
	if redisClient == nil {
		redisStatus = "uninitialized"
	} else if _, err := redisClient.Ping(context.TODO()).Result(); err != nil {
		redisStatus = fmt.Sprintf("unhealthy: %v", err)
	}

	response := map[string]interface{}{
		"status":    "healthy",
		"database":  dbStatus,
		"redis":     redisStatus,
		"timestamp": time.Now().Format(time.RFC3339),
	}

	if dbStatus != "healthy" || redisStatus != "healthy" {
		w.WriteHeader(http.StatusServiceUnavailable)
		response["status"] = "degraded"
	}

	json.NewEncoder(w).Encode(response)
}

func hitsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if redisClient == nil {
		http.Error(w, "Redis client not initialized", http.StatusInternalServerError)
		return
	}

	hits, err := redisClient.Incr(r.Context(), "request_hits").Result()
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to increment hits in Redis: %v", err), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"hits":        hits,
		"cached_hits": true,
		"timestamp":   time.Now().Format(time.RFC3339),
	}
	json.NewEncoder(w).Encode(response)
}

func dbTestHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if dbClient == nil {
		http.Error(w, "Database client not initialized", http.StatusInternalServerError)
		return
	}

	// Insert audit log
	_, err := dbClient.ExecContext(r.Context(), "INSERT INTO audit_logs (action) VALUES ($1)", "user_checked_db")
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to insert audit log: %v", err), http.StatusInternalServerError)
		return
	}

	// Query last 5 entries
	rows, err := dbClient.QueryContext(r.Context(), "SELECT id, action, created_at FROM audit_logs ORDER BY id DESC LIMIT 5")
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to query audit logs: %v", err), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type AuditLog struct {
		ID        int       `json:"id"`
		Action    string    `json:"action"`
		CreatedAt time.Time `json:"created_at"`
	}

	var logs []AuditLog
	for rows.Next() {
		var logEntry AuditLog
		if err := rows.Scan(&logEntry.ID, &logEntry.Action, &logEntry.CreatedAt); err != nil {
			http.Error(w, fmt.Sprintf("Failed to scan row: %v", err), http.StatusInternalServerError)
			return
		}
		logs = append(logs, logEntry)
	}

	response := map[string]interface{}{
		"message":   "Write & Read successfully verified on PostgreSQL",
		"records":   logs,
		"timestamp": time.Now().Format(time.RFC3339),
	}
	json.NewEncoder(w).Encode(response)
}

func awsCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	ssmSvc := ssm.NewFromConfig(awsCfg)
	s3Svc := s3.NewFromConfig(awsCfg)

	// 1. Read config from LocalStack SSM
	ssmParamValue := "Not retrieved"
	paramOut, err := ssmSvc.GetParameter(r.Context(), &ssm.GetParameterInput{
		Name:           aws.String(appConfig.SsmParamPath),
		WithDecryption: aws.Bool(true),
	})
	if err != nil {
		log.Printf("Failed to read parameter from SSM (checking if seeded): %v", err)
		ssmParamValue = fmt.Sprintf("Error: %v", err)
	} else {
		ssmParamValue = *paramOut.Parameter.Value
	}

	// 2. Read object count in S3
	var fileKeys []string
	listOut, err := s3Svc.ListObjectsV2(r.Context(), &s3.ListObjectsV2Input{
		Bucket: aws.String(appConfig.BucketName),
	})
	if err != nil {
		log.Printf("Failed to list objects in S3 bucket: %v", err)
		fileKeys = append(fileKeys, fmt.Sprintf("Error: %v", err))
	} else {
		for _, item := range listOut.Contents {
			fileKeys = append(fileKeys, *item.Key)
		}
	}

	response := map[string]interface{}{
		"localstack_ssm_check": map[string]string{
			"parameter_path": appConfig.SsmParamPath,
			"value":          ssmParamValue,
		},
		"localstack_s3_check": map[string]interface{}{
			"bucket_name": appConfig.BucketName,
			"files":       fileKeys,
			"file_count":  len(fileKeys),
		},
		"timestamp": time.Now().Format(time.RFC3339),
	}
	json.NewEncoder(w).Encode(response)
}
