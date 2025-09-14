#!/bin/bash

# Healthcare DevOps Pipeline - Real Documentation Generation Script
# Generates comprehensive API documentation, architecture diagrams, and project docs

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSION=${1:-"1.0.0"}
OUTPUT_DIR="${PROJECT_ROOT}/docs/generated"
API_DOCS_DIR="${OUTPUT_DIR}/api"
ARCHITECTURE_DOCS_DIR="${OUTPUT_DIR}/architecture"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[DOCS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} [PASS] $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} [WARNING] $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} [ERROR] $1"
}

log_docs() {
    echo -e "${PURPLE}[DOCS]${NC} $1"
}

# Create output directories
create_directories() {
    log_info "Creating output directories..."
    mkdir -p "$OUTPUT_DIR/api"
    mkdir -p "$OUTPUT_DIR/architecture"
    mkdir -p "$OUTPUT_DIR/diagrams"
    log_success "Output directories created"
}

log_docs "Starting Enhanced Documentation Generation"
log_docs "=========================================="
log_info "Project: Healthcare DevOps Pipeline"
log_info "Version: $VERSION"
log_info "Output Directory: $OUTPUT_DIR"

# Generate OpenAPI specification
generate_openapi_spec() {
    log_docs "Generating OpenAPI 3.0 specification..."

    cat > "$OUTPUT_DIR/api/openapi-spec.yaml" << 'EOF'
openapi: 3.0.3
info:
  title: Healthcare DevOps Pipeline API
  description: |
    Comprehensive API for healthcare management system with DevOps pipeline integration.

    ## Features
    - Patient management with full lifecycle tracking
    - Intelligent appointment scheduling with conflict resolution
    - Doctor and staff management with availability tracking
    - Secure electronic health records with audit trails
    - Real-time notifications via WebSocket
    - JWT-based authentication with role-based access control
    - HIPAA, SOC2, and GDPR compliance features

    ## Authentication
    All API endpoints require authentication via JWT token in the Authorization header:
    ```
    Authorization: Bearer <jwt_token>
    ```

    ## Rate Limiting
    - 1000 requests per hour for authenticated users
    - 100 requests per hour for unauthenticated requests
    - Burst limit: 50 requests per minute
  version: '${VERSION}'
  contact:
    name: Healthcare DevOps Team
    email: devops@healthcare-app.com
    url: https://github.com/healthcare-devops-pipeline
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: https://api.healthcare-app.com/v1
    description: Production server
  - url: https://staging-api.healthcare-app.com/v1
    description: Staging server
  - url: http://localhost:30285/api/v1
    description: Local development server

security:
  - bearerAuth: []
  - apiKeyAuth: []

paths:
  /health:
    get:
      summary: System health check
      description: |
        Comprehensive health check endpoint that validates:
        - Database connectivity
        - Redis cache availability
        - External service dependencies
        - System resource usage
      tags:
        - System
      security: []
      responses:
        '200':
          description: System is healthy
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    enum: [healthy, degraded, unhealthy]
                    example: "healthy"
                  timestamp:
                    type: string
                    format: date-time
                  version:
                    type: string
                    example: "1.0.0"
                  uptime:
                    type: integer
                    description: System uptime in seconds
                  services:
                    type: object
                    properties:
                      database:
                        type: string
                        enum: [up, down]
                      redis:
                        type: string
                        enum: [up, down]
                      external_api:
                        type: string
                        enum: [up, down]
        '503':
          description: System is unhealthy
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

  /auth/login:
    post:
      summary: User authentication
      description: Authenticate user credentials and return JWT access token with refresh token
      tags:
        - Authentication
      security: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - email
                - password
              properties:
                email:
                  type: string
                  format: email
                  description: User's email address
                  example: "doctor.smith@hospital.com"
                password:
                  type: string
                  format: password
                  minLength: 8
                  description: User's password
                  example: "SecurePass123!"
                rememberMe:
                  type: boolean
                  default: false
                  description: Extend token expiration for 30 days
      responses:
        '200':
          description: Authentication successful
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    type: object
                    properties:
                      accessToken:
                        type: string
                        description: JWT access token (15 minutes)
                      refreshToken:
                        type: string
                        description: JWT refresh token (30 days)
                      user:
                        $ref: '#/components/schemas/User'
                      expiresIn:
                        type: integer
                        description: Access token expiration in seconds
                        example: 900
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '429':
          $ref: '#/components/responses/RateLimitExceeded'

  /auth/refresh:
    post:
      summary: Refresh access token
      description: Generate new access token using refresh token
      tags:
        - Authentication
      security: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - refreshToken
              properties:
                refreshToken:
                  type: string
                  description: Valid refresh token
      responses:
        '200':
          description: Token refreshed successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  accessToken:
                    type: string
                  expiresIn:
                    type: integer
        '401':
          $ref: '#/components/responses/Unauthorized'

  /auth/logout:
    post:
      summary: User logout
      description: Invalidate current session and refresh token
      tags:
        - Authentication
      responses:
        '200':
          description: Logout successful
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  message:
                    type: string
                    example: "Logged out successfully"

  /auth/me:
    get:
      summary: Get current user profile
      description: Retrieve authenticated user's profile information
      tags:
        - Authentication
      responses:
        '200':
          description: User profile retrieved
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    $ref: '#/components/schemas/User'
        '401':
          $ref: '#/components/responses/Unauthorized'

  /patients:
    get:
      summary: List patients
      description: |
        Retrieve paginated list of patients with optional filtering and search.

        **Permissions Required:** doctor, nurse, admin
      tags:
        - Patients
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            minimum: 1
            default: 1
          description: Page number for pagination
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
          description: Number of items per page
        - name: search
          in: query
          schema:
            type: string
            minLength: 2
          description: Search term for patient name or ID
        - name: status
          in: query
          schema:
            type: string
            enum: [active, inactive, archived]
          description: Filter by patient status
        - name: sortBy
          in: query
          schema:
            type: string
            enum: [name, createdAt, updatedAt, lastVisit]
            default: createdAt
          description: Sort field
        - name: sortOrder
          in: query
          schema:
            type: string
            enum: [asc, desc]
            default: desc
          description: Sort order
      responses:
        '200':
          description: Patients retrieved successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/Patient'
                  pagination:
                    $ref: '#/components/schemas/Pagination'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'

    post:
      summary: Create new patient
      description: |
        Register a new patient in the system.

        **Permissions Required:** doctor, admin
      tags:
        - Patients
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/PatientInput'
      responses:
        '201':
          description: Patient created successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    $ref: '#/components/schemas/Patient'
                  message:
                    type: string
                    example: "Patient created successfully"
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'

  /patients/{id}:
    get:
      summary: Get patient by ID
      description: |
        Retrieve detailed information about a specific patient including medical history.

        **Permissions Required:** doctor, nurse, admin (own records only for patients)
      tags:
        - Patients
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            pattern: '^[0-9a-fA-F]{24}$'
          description: Patient MongoDB ObjectId
      responses:
        '200':
          description: Patient details retrieved
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    $ref: '#/components/schemas/PatientDetail'
        '404':
          $ref: '#/components/responses/NotFound'

    put:
      summary: Update patient
      description: |
        Update patient information. All fields are optional.

        **Permissions Required:** doctor, admin
      tags:
        - Patients
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            pattern: '^[0-9a-fA-F]{24}$'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/PatientUpdate'
      responses:
        '200':
          description: Patient updated successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    $ref: '#/components/schemas/Patient'

    delete:
      summary: Delete patient
      description: |
        Soft delete a patient record. Actual data is retained for compliance.

        **Permissions Required:** admin only
      tags:
        - Patients
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            pattern: '^[0-9a-fA-F]{24}$'
      responses:
        '200':
          description: Patient deleted successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  message:
                    type: string
                    example: "Patient record archived"

  /patients/{id}/medical-records:
    get:
      summary: Get patient medical records
      description: |
        Retrieve patient's medical history and records.

        **Permissions Required:** doctor, nurse, admin
      tags:
        - Patients
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            pattern: '^[0-9a-fA-F]{24}$'
        - name: type
          in: query
          schema:
            type: string
            enum: [all, consultation, procedure, prescription, lab, imaging]
            default: all
      responses:
        '200':
          description: Medical records retrieved
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/MedicalRecord'

  /appointments:
    get:
      summary: List appointments
      description: |
        Retrieve appointments with filtering options.

        **Permissions Required:** doctor, nurse, admin
      tags:
        - Appointments
      parameters:
        - name: date
          in: query
          schema:
            type: string
            format: date
          description: Filter by appointment date
        - name: doctorId
          in: query
          schema:
            type: string
            pattern: '^[0-9a-fA-F]{24}$'
          description: Filter by doctor ID
        - name: patientId
          in: query
          schema:
            type: string
            pattern: '^[0-9a-fA-F]{24}$'
          description: Filter by patient ID
        - name: status
          in: query
          schema:
            type: string
            enum: [scheduled, confirmed, in-progress, completed, cancelled, no-show]
          description: Filter by appointment status
        - name: page
          in: query
          schema:
            type: integer
            minimum: 1
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
      responses:
        '200':
          description: Appointments retrieved successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/Appointment'
                  pagination:
                    $ref: '#/components/schemas/Pagination'

    post:
      summary: Create appointment
      description: |
        Schedule a new appointment with conflict checking.

        **Permissions Required:** doctor, nurse, admin
      tags:
        - Appointments
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/AppointmentInput'
      responses:
        '201':
          description: Appointment created successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    $ref: '#/components/schemas/Appointment'
        '400':
          $ref: '#/components/responses/BadRequest'
        '409':
          description: Appointment conflict
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: false
                  error:
                    type: string
                    example: "APPOINTMENT_CONFLICT"
                  message:
                    type: string
                    example: "Doctor is not available at the requested time"

  /appointments/{id}:
    get:
      summary: Get appointment details
      description: Retrieve detailed appointment information
      tags:
        - Appointments
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            pattern: '^[0-9a-fA-F]{24}$'
      responses:
        '200':
          description: Appointment details retrieved
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    $ref: '#/components/schemas/AppointmentDetail'

    put:
      summary: Update appointment
      description: Update appointment details
      tags:
        - Appointments
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            pattern: '^[0-9a-fA-F]{24}$'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/AppointmentUpdate'
      responses:
        '200':
          description: Appointment updated successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    $ref: '#/components/schemas/Appointment'

    delete:
      summary: Cancel appointment
      description: Cancel an appointment
      tags:
        - Appointments
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            pattern: '^[0-9a-fA-F]{24}$'
      responses:
        '200':
          description: Appointment cancelled successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  message:
                    type: string
                    example: "Appointment cancelled"

  /doctors:
    get:
      summary: List doctors
      description: Retrieve list of doctors with filtering
      tags:
        - Doctors
      parameters:
        - name: specialty
          in: query
          schema:
            type: string
          description: Filter by medical specialty
        - name: availability
          in: query
          schema:
            type: string
            enum: [available, busy, off-duty]
          description: Filter by current availability
        - name: page
          in: query
          schema:
            type: integer
            minimum: 1
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 50
            default: 20
      responses:
        '200':
          description: Doctors retrieved successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/Doctor'
                  pagination:
                    $ref: '#/components/schemas/Pagination'

  /doctors/{id}/availability:
    get:
      summary: Get doctor availability
      description: Retrieve doctor's availability schedule
      tags:
        - Doctors
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            pattern: '^[0-9a-fA-F]{24}$'
        - name: date
          in: query
          schema:
            type: string
            format: date
          description: Date to check availability for
      responses:
        '200':
          description: Availability retrieved successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    type: object
                    properties:
                      doctorId:
                        type: string
                      date:
                        type: string
                        format: date
                      availableSlots:
                        type: array
                        items:
                          type: object
                          properties:
                            startTime:
                              type: string
                              format: date-time
                            endTime:
                              type: string
                              format: date-time
                            duration:
                              type: integer
                              description: Duration in minutes

  /admin/metrics:
    get:
      summary: Get system metrics
      description: |
        Retrieve system performance and health metrics.

        **Permissions Required:** admin only
      tags:
        - Administration
      responses:
        '200':
          description: Metrics retrieved successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    type: object
                    properties:
                      system:
                        $ref: '#/components/schemas/SystemMetrics'
                      application:
                        $ref: '#/components/schemas/ApplicationMetrics'
                      database:
                        $ref: '#/components/schemas/DatabaseMetrics'

  /admin/audit-logs:
    get:
      summary: Get audit logs
      description: |
        Retrieve system audit logs for compliance and security monitoring.

        **Permissions Required:** admin only
      tags:
        - Administration
      parameters:
        - name: startDate
          in: query
          schema:
            type: string
            format: date
          description: Start date for audit logs
        - name: endDate
          in: query
          schema:
            type: string
            format: date
          description: End date for audit logs
        - name: action
          in: query
          schema:
            type: string
          description: Filter by action type
        - name: userId
          in: query
          schema:
            type: string
          description: Filter by user ID
      responses:
        '200':
          description: Audit logs retrieved successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    example: true
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/AuditLog'

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT Authorization header using the Bearer scheme
    apiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
      description: API Key for service-to-service authentication

  schemas:
    User:
      type: object
      properties:
        id:
          type: string
          description: User unique identifier
          example: "507f1f77bcf86cd799439011"
        email:
          type: string
          format: email
          description: User's email address
          example: "doctor.smith@hospital.com"
        firstName:
          type: string
          description: User's first name
          example: "John"
        lastName:
          type: string
          description: User's last name
          example: "Smith"
        role:
          type: string
          enum: [admin, doctor, nurse, patient]
          description: User's role in the system
          example: "doctor"
        isActive:
          type: boolean
          description: Whether the user account is active
          example: true
        lastLogin:
          type: string
          format: date-time
          description: Last login timestamp
        createdAt:
          type: string
          format: date-time
          description: Account creation timestamp
        updatedAt:
          type: string
          format: date-time
          description: Last update timestamp

    Patient:
      type: object
      properties:
        id:
          type: string
          description: Patient unique identifier
          example: "507f1f77bcf86cd799439011"
        firstName:
          type: string
          example: "John"
        lastName:
          type: string
          example: "Doe"
        email:
          type: string
          format: email
          example: "john.doe@email.com"
        phone:
          type: string
          example: "+1-555-0123"
        dateOfBirth:
          type: string
          format: date
          example: "1980-01-15"
        gender:
          type: string
          enum: [male, female, other]
          example: "male"
        address:
          type: object
          properties:
            street:
              type: string
              example: "123 Main St"
            city:
              type: string
              example: "New York"
            state:
              type: string
              example: "NY"
            zipCode:
              type: string
              example: "10001"
            country:
              type: string
              example: "USA"
        medicalRecordNumber:
          type: string
          description: Unique medical record number
          example: "MRN123456789"
        emergencyContact:
          type: object
          properties:
            name:
              type: string
              example: "Jane Doe"
            phone:
              type: string
              example: "+1-555-0987"
            relationship:
              type: string
              example: "Spouse"
        insurance:
          type: object
          properties:
            provider:
              type: string
              example: "Blue Cross Blue Shield"
            policyNumber:
              type: string
              example: "POL123456789"
            groupNumber:
              type: string
              example: "GRP987654321"
        status:
          type: string
          enum: [active, inactive, archived]
          default: active
          example: "active"
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    PatientInput:
      type: object
      required:
        - firstName
        - lastName
        - email
        - dateOfBirth
        - gender
      properties:
        firstName:
          type: string
          minLength: 1
          maxLength: 50
        lastName:
          type: string
          minLength: 1
          maxLength: 50
        email:
          type: string
          format: email
        phone:
          type: string
          pattern: '^\+?[1-9]\d{1,14}$'
        dateOfBirth:
          type: string
          format: date
        gender:
          type: string
          enum: [male, female, other]
        address:
          type: object
          properties:
            street:
              type: string
              minLength: 1
              maxLength: 100
            city:
              type: string
              minLength: 1
              maxLength: 50
            state:
              type: string
              minLength: 1
              maxLength: 50
            zipCode:
              type: string
              pattern: '^\d{5}(-\d{4})?$'
            country:
              type: string
              minLength: 1
              maxLength: 50
        emergencyContact:
          type: object
          properties:
            name:
              type: string
              minLength: 1
              maxLength: 100
            phone:
              type: string
              pattern: '^\+?[1-9]\d{1,14}$'
            relationship:
              type: string
              minLength: 1
              maxLength: 50
        insurance:
          type: object
          properties:
            provider:
              type: string
              minLength: 1
              maxLength: 100
            policyNumber:
              type: string
              minLength: 1
              maxLength: 50
            groupNumber:
              type: string
              minLength: 1
              maxLength: 50

    PatientUpdate:
      type: object
      properties:
        firstName:
          type: string
          minLength: 1
          maxLength: 50
        lastName:
          type: string
          minLength: 1
          maxLength: 50
        email:
          type: string
          format: email
        phone:
          type: string
          pattern: '^\+?[1-9]\d{1,14}$'
        address:
          type: object
          properties:
            street:
              type: string
              minLength: 1
              maxLength: 100
            city:
              type: string
              minLength: 1
              maxLength: 50
            state:
              type: string
              minLength: 1
              maxLength: 50
            zipCode:
              type: string
              pattern: '^\d{5}(-\d{4})?$'
            country:
              type: string
              minLength: 1
              maxLength: 50
        emergencyContact:
          type: object
          properties:
            name:
              type: string
              minLength: 1
              maxLength: 100
            phone:
              type: string
              pattern: '^\+?[1-9]\d{1,14}$'
            relationship:
              type: string
              minLength: 1
              maxLength: 50
        insurance:
          type: object
          properties:
            provider:
              type: string
              minLength: 1
              maxLength: 100
            policyNumber:
              type: string
              minLength: 1
              maxLength: 50
            groupNumber:
              type: string
              minLength: 1
              maxLength: 50
        status:
          type: string
          enum: [active, inactive, archived]

    PatientDetail:
      allOf:
        - $ref: '#/components/schemas/Patient'
        - type: object
          properties:
            medicalHistory:
              type: array
              items:
                $ref: '#/components/schemas/MedicalRecord'
            allergies:
              type: array
              items:
                type: object
                properties:
                  allergen:
                    type: string
                    example: "Penicillin"
                  severity:
                    type: string
                    enum: [mild, moderate, severe]
                    example: "severe"
                  reaction:
                    type: string
                    example: "Rash, difficulty breathing"
            currentMedications:
              type: array
              items:
                type: object
                properties:
                  name:
                    type: string
                    example: "Lisinopril"
                  dosage:
                    type: string
                    example: "10mg"
                  frequency:
                    type: string
                    example: "Once daily"
                  prescribedDate:
                    type: string
                    format: date
                  prescribingDoctor:
                    type: string
                    example: "Dr. Smith"

    MedicalRecord:
      type: object
      properties:
        id:
          type: string
          example: "507f1f77bcf86cd799439011"
        type:
          type: string
          enum: [consultation, procedure, prescription, lab, imaging, note]
          example: "consultation"
        date:
          type: string
          format: date-time
          example: "2023-12-01T10:00:00Z"
        provider:
          type: string
          example: "Dr. Sarah Johnson"
        description:
          type: string
          example: "Annual physical examination"
        diagnosis:
          type: array
          items:
            type: string
          example: ["Hypertension", "Type 2 Diabetes"]
        treatment:
          type: string
          example: "Prescribed metformin 500mg twice daily"
        notes:
          type: string
          example: "Patient reports improved energy levels"
        attachments:
          type: array
          items:
            type: object
            properties:
              filename:
                type: string
                example: "blood_test_results.pdf"
              url:
                type: string
                example: "/api/files/507f1f77bcf86cd799439011"
              contentType:
                type: string
                example: "application/pdf"

    Appointment:
      type: object
      properties:
        id:
          type: string
          example: "507f1f77bcf86cd799439011"
        patientId:
          type: string
          example: "507f1f77bcf86cd799439012"
        patientName:
          type: string
          example: "John Doe"
        doctorId:
          type: string
          example: "507f1f77bcf86cd799439013"
        doctorName:
          type: string
          example: "Dr. Sarah Johnson"
        date:
          type: string
          format: date
          example: "2023-12-15"
        startTime:
          type: string
          format: date-time
          example: "2023-12-15T10:00:00Z"
        endTime:
          type: string
          format: date-time
          example: "2023-12-15T10:30:00Z"
        duration:
          type: integer
          description: Duration in minutes
          example: 30
        type:
          type: string
          enum: [consultation, follow-up, procedure, emergency, telemedicine]
          example: "consultation"
        status:
          type: string
          enum: [scheduled, confirmed, checked-in, in-progress, completed, cancelled, no-show]
          example: "scheduled"
        priority:
          type: string
          enum: [low, normal, high, urgent]
          default: normal
          example: "normal"
        notes:
          type: string
          example: "Follow-up on blood pressure medication"
        location:
          type: object
          properties:
            type:
              type: string
              enum: [clinic, telemedicine, home-visit]
              example: "clinic"
            room:
              type: string
              example: "Room 205"
            address:
              type: string
              example: "123 Medical Center Dr"
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    AppointmentInput:
      type: object
      required:
        - patientId
        - doctorId
        - date
        - startTime
        - type
      properties:
        patientId:
          type: string
          pattern: '^[0-9a-fA-F]{24}$'
        doctorId:
          type: string
          pattern: '^[0-9a-fA-F]{24}$'
        date:
          type: string
          format: date
        startTime:
          type: string
          format: date-time
        duration:
          type: integer
          minimum: 15
          maximum: 480
          default: 30
        type:
          type: string
          enum: [consultation, follow-up, procedure, emergency, telemedicine]
        priority:
          type: string
          enum: [low, normal, high, urgent]
          default: normal
        notes:
          type: string
          maxLength: 1000
        location:
          type: object
          properties:
            type:
              type: string
              enum: [clinic, telemedicine, home-visit]
              default: clinic
            room:
              type: string
              maxLength: 50
            address:
              type: string
              maxLength: 200

    AppointmentUpdate:
      type: object
      properties:
        date:
          type: string
          format: date
        startTime:
          type: string
          format: date-time
        duration:
          type: integer
          minimum: 15
          maximum: 480
        type:
          type: string
          enum: [consultation, follow-up, procedure, emergency, telemedicine]
        status:
          type: string
          enum: [scheduled, confirmed, checked-in, in-progress, completed, cancelled, no-show]
        priority:
          type: string
          enum: [low, normal, high, urgent]
        notes:
          type: string
          maxLength: 1000
        location:
          type: object
          properties:
            type:
              type: string
              enum: [clinic, telemedicine, home-visit]
            room:
              type: string
              maxLength: 50
            address:
              type: string
              maxLength: 200

    AppointmentDetail:
      allOf:
        - $ref: '#/components/schemas/Appointment'
        - type: object
          properties:
            patient:
              $ref: '#/components/schemas/Patient'
            doctor:
              $ref: '#/components/schemas/Doctor'
            vitals:
              type: object
              properties:
                bloodPressure:
                  type: string
                  example: "120/80"
                heartRate:
                  type: integer
                  example: 72
                temperature:
                  type: number
                  example: 98.6
                weight:
                  type: number
                  example: 175.5
                height:
                  type: number
                  example: 70.0
            diagnosis:
              type: array
              items:
                type: string
              example: ["Hypertension", "Obesity"]
            prescription:
              type: array
              items:
                type: object
                properties:
                  medication:
                    type: string
                    example: "Lisinopril"
                  dosage:
                    type: string
                    example: "10mg"
                  frequency:
                    type: string
                    example: "Once daily"

    Doctor:
      type: object
      properties:
        id:
          type: string
          example: "507f1f77bcf86cd799439011"
        firstName:
          type: string
          example: "Sarah"
        lastName:
          type: string
          example: "Johnson"
        email:
          type: string
          format: email
          example: "sarah.johnson@hospital.com"
        phone:
          type: string
          example: "+1-555-0199"
        specialty:
          type: string
          example: "Cardiology"
        licenseNumber:
          type: string
          example: "MD123456789"
        department:
          type: string
          example: "Cardiology Department"
        qualifications:
          type: array
          items:
            type: string
          example: ["MD", "Board Certified Cardiologist", "Fellow of the American College of Cardiology"]
        languages:
          type: array
          items:
            type: string
          example: ["English", "Spanish"]
        isActive:
          type: boolean
          default: true
          example: true
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    Pagination:
      type: object
      properties:
        page:
          type: integer
          example: 1
        limit:
          type: integer
          example: 20
        total:
          type: integer
          example: 150
        totalPages:
          type: integer
          example: 8
        hasNext:
          type: boolean
          example: true
        hasPrev:
          type: boolean
          example: false

    SystemMetrics:
      type: object
      properties:
        cpu:
          type: object
          properties:
            usage:
              type: number
              example: 45.5
            cores:
              type: integer
              example: 4
        memory:
          type: object
          properties:
            used:
              type: integer
              example: 2048
            total:
              type: integer
              example: 4096
            percentage:
              type: number
              example: 50.0
        disk:
          type: object
          properties:
            used:
              type: integer
              example: 150
            total:
              type: integer
              example: 500
            percentage:
              type: number
              example: 30.0
        uptime:
          type: integer
          description: System uptime in seconds
          example: 86400

    ApplicationMetrics:
      type: object
      properties:
        activeUsers:
          type: integer
          example: 150
        totalRequests:
          type: integer
          example: 12500
        averageResponseTime:
          type: number
          example: 245.5
        errorRate:
          type: number
          example: 0.02
        throughput:
          type: number
          example: 125.5

    DatabaseMetrics:
      type: object
      properties:
        connections:
          type: object
          properties:
            active:
              type: integer
              example: 15
            available:
              type: integer
              example: 35
            total:
              type: integer
              example: 50
        queryPerformance:
          type: object
          properties:
            slowQueries:
              type: integer
              example: 2
            averageQueryTime:
              type: number
              example: 45.2
        storage:
          type: object
          properties:
            used:
              type: integer
              example: 2500
            total:
              type: integer
              example: 10000
            collections:
              type: integer
              example: 25

    AuditLog:
      type: object
      properties:
        id:
          type: string
          example: "507f1f77bcf86cd799439011"
        timestamp:
          type: string
          format: date-time
          example: "2023-12-01T10:30:00Z"
        userId:
          type: string
          example: "507f1f77bcf86cd799439012"
        userEmail:
          type: string
          format: email
          example: "doctor.smith@hospital.com"
        action:
          type: string
          enum: [login, logout, create, read, update, delete, export]
          example: "update"
        resource:
          type: string
          enum: [patient, appointment, doctor, user, medical_record]
          example: "patient"
        resourceId:
          type: string
          example: "507f1f77bcf86cd799439013"
        ipAddress:
          type: string
          example: "192.168.1.100"
        userAgent:
          type: string
          example: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        details:
          type: object
          description: Additional action details
          example: {"field": "phone", "oldValue": "+1-555-0123", "newValue": "+1-555-0124"}

    ErrorResponse:
      type: object
      properties:
        success:
          type: boolean
          example: false
        error:
          type: string
          example: "VALIDATION_ERROR"
        message:
          type: string
          example: "Input validation failed"
        details:
          type: array
          items:
            type: object
            properties:
              field:
                type: string
                example: "email"
              message:
                type: string
                example: "Email is required"
        timestamp:
          type: string
          format: date-time
        requestId:
          type: string
          example: "req_507f1f77bcf86cd799439011"

  responses:
    BadRequest:
      description: Bad Request - Invalid input parameters
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    Unauthorized:
      description: Unauthorized - Authentication required
      content:
        application/json:
          schema:
            type: object
            properties:
              success:
                type: boolean
                example: false
              error:
                type: string
                example: "UNAUTHORIZED"
              message:
                type: string
                example: "Authentication required"
              timestamp:
                type: string
                format: date-time

    Forbidden:
      description: Forbidden - Insufficient permissions
      content:
        application/json:
          schema:
            type: object
            properties:
              success:
                type: boolean
                example: false
              error:
                type: string
                example: "FORBIDDEN"
              message:
                type: string
                example: "Insufficient permissions"
              timestamp:
                type: string
                format: date-time

    NotFound:
      description: Not Found - Resource does not exist
      content:
        application/json:
          schema:
            type: object
            properties:
              success:
                type: boolean
                example: false
              error:
                type: string
                example: "NOT_FOUND"
              message:
                type: string
                example: "Resource not found"
              timestamp:
                type: string
                format: date-time

    RateLimitExceeded:
      description: Rate Limit Exceeded - Too many requests
      content:
        application/json:
          schema:
            type: object
            properties:
              success:
                type: boolean
                example: false
              error:
                type: string
                example: "RATE_LIMIT_EXCEEDED"
              message:
                type: string
                example: "Too many requests. Please try again later."
              retryAfter:
                type: integer
                description: Seconds to wait before retrying
                example: 60
              timestamp:
                type: string
                format: date-time

  parameters:
    patientId:
      name: patientId
      in: path
      required: true
      schema:
        type: string
        pattern: '^[0-9a-fA-F]{24}$'
      description: Patient MongoDB ObjectId

    appointmentId:
      name: appointmentId
      in: path
      required: true
      schema:
        type: string
        pattern: '^[0-9a-fA-F]{24}$'
      description: Appointment MongoDB ObjectId

    doctorId:
      name: doctorId
      in: path
      required: true
      schema:
        type: string
        pattern: '^[0-9a-fA-F]{24}$'
      description: Doctor MongoDB ObjectId
EOF

    log_success "OpenAPI 3.0 specification generated"
}

# Generate JSDoc documentation for backend
generate_jsdoc() {
    log_docs "Generating JSDoc documentation..."

    if command -v npx &> /dev/null; then
        # Create JSDoc configuration
        cat > jsdoc-config.json << 'EOF'
{
  "source": {
    "include": ["server/", "src/"],
    "includePattern": "\\.(js|jsx|ts|tsx)$",
    "exclude": ["node_modules/", "build/", "coverage/"]
  },
  "opts": {
    "destination": "'$OUTPUT_DIR'/api/jsdoc/",
    "recurse": true,
    "readme": "README.md"
  },
  "plugins": ["plugins/markdown"],
  "templates": {
    "default": {
      "outputSourceFiles": true
    }
  }
}
EOF

        # Generate JSDoc
        npx jsdoc -c jsdoc-config.json

        # Clean up config file
        rm jsdoc-config.json

        log_success "JSDoc documentation generated"
    else
        log_warning "npx not available - skipping JSDoc generation"
    fi
}

# Generate architecture documentation
generate_architecture_docs() {
    log_docs "Generating architecture documentation..."

    # System Architecture Overview
    cat > "$OUTPUT_DIR/architecture/system-overview.md" << EOF
# System Architecture Overview

## Healthcare DevOps Pipeline Architecture

### High-Level Architecture

\`\`\`mermaid
graph TB
    subgraph "CI/CD Pipeline"
        A[Jenkins] --> B[Build Stage]
        B --> C[Test Stage]
        C --> D[Code Quality]
        D --> E[Security Scan]
        E --> F[Deploy Stage]
        F --> G[Canary Release]
        G --> H[Blue-Green Deploy]
        H --> I[Production Release]
    end

    subgraph "Application Stack"
        J[React Frontend] --> K[Node.js API]
        K --> L[MongoDB]
        K --> M[Redis Cache]
    end

    subgraph "Infrastructure"
        N[Docker] --> O[Kubernetes]
        O --> P[Terraform]
        P --> Q[AWS/GCP/Azure]
    end

    subgraph "Monitoring & Observability"
        R[Prometheus] --> S[Grafana]
        R --> T[AlertManager]
        U[Datadog] --> V[APM & Logs]
        W[Jaeger] --> X[Distributed Tracing]
    end

    A --> J
    I --> N
    N --> R
    N --> U
    N --> W
\`\`\`

### Component Details

#### Frontend Layer
- **Technology**: React 18 with TypeScript
- **Features**:
  - Responsive UI with Material-UI
  - Real-time updates with WebSocket
  - PWA capabilities
  - Accessibility compliance (WCAG 2.1 AA)

#### Backend Layer
- **Technology**: Node.js with Express.js
- **Features**:
  - RESTful API design
  - JWT authentication
  - Rate limiting and security middleware
  - Database connection pooling
  - Background job processing

#### Data Layer
- **Primary Database**: MongoDB
- **Caching**: Redis
- **Features**:
  - Data encryption at rest
  - Automated backups
  - Read/write splitting
  - Connection pooling

#### Infrastructure Layer
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **Infrastructure as Code**: Terraform
- **Cloud Providers**: Multi-cloud support

#### DevOps Pipeline
- **CI/CD**: Jenkins with declarative pipelines
- **Version Control**: Git with GitFlow
- **Artifact Repository**: Docker Registry
- **Configuration Management**: Kubernetes ConfigMaps/Secrets

### Security Architecture

#### Authentication & Authorization
- JWT-based authentication
- Role-based access control (RBAC)
- Multi-factor authentication (MFA)
- Session management with Redis

#### Data Protection
- TLS 1.3 encryption in transit
- AES-256 encryption at rest
- Database field-level encryption
- Secure key management

#### Network Security
- VPC isolation
- Security groups and network ACLs
- Web Application Firewall (WAF)
- DDoS protection

#### Compliance
- HIPAA compliance for healthcare data
- SOC 2 Type II compliance
- GDPR compliance for EU data
- Regular security audits

### Performance Characteristics

#### Response Times
- API endpoints: <200ms average
- Page load: <2s
- Database queries: <50ms

#### Scalability
- Horizontal pod scaling
- Database read replicas
- CDN for static assets
- Auto-scaling based on metrics

#### Availability
- 99.9% uptime SLA
- Multi-zone deployment
- Automated failover
- Disaster recovery procedures

### Monitoring & Alerting

#### Application Metrics
- Request/response metrics
- Error rates and types
- Database connection pools
- Cache hit/miss ratios

#### Infrastructure Metrics
- CPU and memory usage
- Network I/O
- Disk I/O and space
- Container health

#### Business Metrics
- User registration rates
- Appointment booking rates
- System usage patterns
- Performance KPIs

### Deployment Strategy

#### Development Environment
- Local development with Docker Compose
- Hot reloading for frontend/backend
- Automated testing on commits

#### Staging Environment
- Full infrastructure deployment
- Integration testing
- Performance testing
- Security scanning

#### Production Environment
- Blue-green deployments
- Canary releases for high-risk changes
- Automated rollback capabilities
- Comprehensive monitoring

### Disaster Recovery

#### Backup Strategy
- Database backups every 6 hours
- Configuration backups daily
- Application artifacts versioning
- Infrastructure state backups

#### Recovery Procedures
- RTO: 4 hours
- RPO: 1 hour
- Automated failover to secondary region
- Manual intervention for critical incidents

#### Testing
- Regular disaster recovery drills
- Automated failover testing
- Data restoration testing
- Performance validation post-recovery
EOF

    # Deployment Architecture
    cat > "$OUTPUT_DIR/architecture/deployment-architecture.md" << EOF
# Deployment Architecture

## Blue-Green Deployment Strategy

### Overview
Blue-green deployment is a technique that reduces downtime and risk by running two identical production environments called Blue and Green.

### Process Flow

\`\`\`mermaid
sequenceDiagram
    participant User
    participant LoadBalancer
    participant Blue
    participant Green
    participant Jenkins

    Note over Jenkins: Deployment Process
    Jenkins->>Green: Deploy new version
    Jenkins->>Green: Run health checks
    Jenkins->>LoadBalancer: Switch traffic to Green
    LoadBalancer->>Green: Route all traffic
    Jenkins->>Blue: Monitor for issues
    Jenkins->>Blue: Scale down Blue environment
\`\`\`

### Benefits
- **Zero Downtime**: Traffic switching is instantaneous
- **Instant Rollback**: Switch back to blue if issues detected
- **Risk Reduction**: Test in production-like environment
- **Gradual Rollout**: Can implement canary releases

## Canary Deployment Strategy

### Overview
Canary deployment gradually rolls out changes to a small subset of users before full release.

### Process Flow

\`\`\`mermaid
sequenceDiagram
    participant User
    participant LoadBalancer
    participant Stable
    participant Canary
    participant Monitoring

    User->>LoadBalancer: Request
    LoadBalancer->>Stable: 90% traffic
    LoadBalancer->>Canary: 10% traffic
    Monitoring->>Canary: Health metrics
    Monitoring->>LoadBalancer: Performance analysis
    LoadBalancer->>Canary: Increase traffic (20%)
    LoadBalancer->>Canary: Full traffic (100%)
\`\`\`

### Benefits
- **Risk Mitigation**: Test with real users
- **Performance Validation**: Monitor impact on real traffic
- **Gradual Rollout**: Control exposure to new features
- **Automated Rollback**: Based on metrics thresholds

## Infrastructure Components

### Kubernetes Architecture

\`\`\`yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: healthcare-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
      - name: frontend
        image: healthcare-app-frontend:latest
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
      - name: backend
        image: healthcare-app-backend:latest
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 1000m
            memory: 1Gi
\`\`\`

### Service Mesh Configuration

\`\`\`yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: healthcare-app
spec:
  http:
  - match:
    - headers:
        x-canary:
          exact: "true"
    route:
    - destination:
        host: healthcare-app-canary
  - route:
    - destination:
        host: healthcare-app-stable
      weight: 90
    - destination:
        host: healthcare-app-canary
      weight: 10
\`\`\`

### Monitoring Stack

\`\`\`yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: healthcare-app-alerts
spec:
  groups:
  - name: healthcare-app
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate detected"
        description: "Error rate is {{ \$value }}% which is above 5%"
\`\`\`
EOF

    log_success "Architecture documentation generated"
}

# Generate deployment documentation
generate_deployment_docs() {
    log_docs "Generating deployment documentation..."

    cat > $OUTPUT_DIR/deployment-guide.md << EOF
# Deployment Guide

## Prerequisites

### System Requirements
- Kubernetes cluster (v1.19+)
- kubectl configured
- Docker registry access
- Terraform (v1.0+)
- Helm (v3.0+)

### Required Tools
\`\`\`bash
# Install required tools
brew install kubectl terraform helm
# or
apt-get install kubectl terraform helm
\`\`\`

## Quick Start Deployment

### 1. Clone Repository
\`\`\`bash
git clone https://github.com/arsh-dang/healthcare-devops-pipeline.git
cd healthcare-devops-pipeline
\`\`\`

### 2. Configure Environment
\`\`\`bash
# Copy environment configuration
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit configuration
vim terraform/terraform.tfvars
\`\`\`

### 3. Deploy Infrastructure
\`\`\`bash
# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
\`\`\`

### 4. Deploy Application
\`\`\`bash
# Build and push Docker images
./scripts/build-and-push.sh

# Deploy to Kubernetes
kubectl apply -f k8s/
\`\`\`

## Environment Configuration

### Staging Environment
\`\`\`hcl
environment = "staging"

# Application settings
app_version = "latest"
frontend_image = "healthcare-app-frontend:staging"
backend_image = "healthcare-app-backend:staging"

# Database settings
mongodb_root_password = "staging-password"

# Monitoring settings
enable_monitoring = true
enable_datadog = true
\`\`\`

### Production Environment
\`\`\`hcl
environment = "production"

# Application settings
app_version = "v1.2.3"
frontend_image = "healthcare-app-frontend:v1.2.3"
backend_image = "healthcare-app-backend:v1.2.3"

# Database settings
mongodb_root_password = "\${var.mongodb_production_password}"

# Monitoring settings
enable_monitoring = true
enable_datadog = true
datadog_api_key = "\${var.datadog_api_key}"
\`\`\`

## Blue-Green Deployment

### Manual Blue-Green Deployment
\`\`\`bash
# Deploy to green environment
kubectl set image deployment/healthcare-app-green \\
  frontend=healthcare-app-frontend:v1.2.3 \\
  backend=healthcare-app-backend:v1.2.3

# Wait for deployment
kubectl rollout status deployment/healthcare-app-green

# Switch traffic to green
kubectl patch service healthcare-app -p '{
  "spec": {
    "selector": {
      "environment": "green"
    }
  }
}'

# Verify deployment
curl https://api.healthcare-app.com/health
\`\`\`

### Automated Blue-Green Deployment
\`\`\`bash
# Use the production deployment script
./scripts/production-deploy.sh production v1.2.3
\`\`\`

## Monitoring Setup

### Grafana Access
\`\`\`bash
# Port forward Grafana
kubectl port-forward svc/grafana 3000:3000

# Access at: http://localhost:30285
# Default credentials: admin/admin
\`\`\`

### Prometheus Access
\`\`\`bash
# Port forward Prometheus
kubectl port-forward svc/prometheus 9090:9090

# Access at: http://localhost:30285/prometheus
\`\`\`

### Datadog Integration
\`\`\`bash
# Set Datadog API key
export DATADOG_API_KEY=your-api-key

# Deploy Datadog agent
helm repo add datadog https://helm.datadoghq.com
helm install datadog datadog/datadog \\
  --set datadog.apiKey=\$DATADOG_API_KEY \\
  --set datadog.appKey=\$DATADOG_APP_KEY
\`\`\`

## Troubleshooting

### Common Issues

#### Pods Not Starting
\`\`\`bash
# Check pod status
kubectl get pods

# Check pod logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
\`\`\`

#### Database Connection Issues
\`\`\`bash
# Check MongoDB pod
kubectl get pods -l app=mongodb

# Check MongoDB logs
kubectl logs -l app=mongodb

# Test database connection
kubectl exec -it <mongodb-pod> -- mongo --eval "db.runCommand('ping')"
\`\`\`

#### Service Mesh Issues
\`\`\`bash
# Check Istio sidecar injection
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].name}'

# Check Istio configuration
kubectl get virtualservice, destinationrule, gateway
\`\`\`

### Health Checks

#### Application Health
\`\`\`bash
# Frontend health
curl http://localhost:30285

# Backend health
curl http://localhost:30285/api/health

# Database health
curl http://localhost:30285/api/health/database
\`\`\`

#### Infrastructure Health
\`\`\`bash
# Kubernetes nodes
kubectl get nodes

# Cluster resources
kubectl top nodes
kubectl top pods

# Storage
kubectl get pvc
\`\`\`

## Backup and Recovery

### Database Backup
\`\`\`bash
# Create database backup
kubectl exec -it <mongodb-pod> -- mongodump --out /backup/\$(date +%Y%m%d_%H%M%S)

# Copy backup to local
kubectl cp <mongodb-pod>:/backup /local/backup/path
\`\`\`

### Configuration Backup
\`\`\`bash
# Backup Kubernetes resources
kubectl get all -o yaml > k8s-backup.yaml

# Backup Terraform state
cp terraform/terraform.tfstate terraform/terraform.tfstate.backup
\`\`\`

### Recovery Procedures
\`\`\`bash
# Restore from backup
kubectl apply -f k8s-backup.yaml

# Restore database
kubectl cp backup.tar.gz <mongodb-pod>:/tmp/
kubectl exec -it <mongodb-pod> -- tar xzf /tmp/backup.tar.gz -C /
kubectl exec -it <mongodb-pod> -- mongorestore /backup
\`\`\`
EOF

    log_success "Deployment documentation generated"
}

# Generate comprehensive README
generate_readme() {
    log_docs "Generating comprehensive README..."

    cat > $OUTPUT_DIR/README.md << EOF
# Healthcare DevOps Pipeline

[![Build Status](https://jenkins.healthcare-app.com/buildStatus/icon?job=healthcare-devops-pipeline)](https://jenkins.healthcare-app.com/job/healthcare-devops-pipeline/)
[![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=healthcare-devops-pipeline&metric=alert_status)](https://sonarcloud.io/dashboard?id=healthcare-devops-pipeline)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=healthcare-devops-pipeline&metric=security_rating)](https://sonarcloud.io/dashboard?id=healthcare-devops-pipeline)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=healthcare-devops-pipeline&metric=coverage)](https://sonarcloud.io/dashboard?id=healthcare-devops-pipeline)

A comprehensive healthcare management system with enterprise-grade DevOps pipeline, implementing all 7 stages of CI/CD with advanced deployment strategies and monitoring.

## 🚀 Features

### Core Functionality
- **Patient Management**: Complete patient lifecycle management
- **Appointment Scheduling**: Intelligent scheduling with conflict resolution
- **Doctor Management**: Staff scheduling and availability management
- **Medical Records**: Secure electronic health records
- **Real-time Notifications**: WebSocket-based notifications
- **Authentication & Authorization**: JWT-based auth with role-based access

### DevOps Pipeline
- **7-Stage CI/CD**: Complete automation from code to production
- **Blue-Green Deployments**: Zero-downtime releases
- **Canary Releases**: Gradual rollout with automated rollback
- **Advanced Monitoring**: Prometheus, Grafana, Datadog integration
- **Security Scanning**: Multi-layer security analysis
- **Load Testing**: Artillery-based performance testing
- **Chaos Engineering**: Automated resilience testing

### Enterprise Features
- **Multi-environment**: Development, staging, production
- **Infrastructure as Code**: Terraform-based infrastructure
- **Container Orchestration**: Kubernetes with service mesh
- **Monitoring & Alerting**: Comprehensive observability stack
- **Backup & Recovery**: Automated disaster recovery
- **Compliance**: HIPAA, SOC 2, GDPR compliance ready

## 🏗️ Architecture

### System Overview
\`\`\`mermaid
graph TB
    A[React Frontend] --> B[Node.js API]
    B --> C[MongoDB]
    B --> D[Redis Cache]
    B --> E[External APIs]

    F[Docker] --> G[Kubernetes]
    G --> H[Terraform]
    H --> I[Cloud Provider]

    J[Prometheus] --> K[Grafana]
    J --> L[AlertManager]
    M[Datadog] --> N[APM & Logs]
    O[Jaeger] --> P[Distributed Tracing]
\`\`\`

### Technology Stack

#### Frontend
- **React 18** with TypeScript
- **Material-UI** for components
- **Redux Toolkit** for state management
- **React Router** for navigation
- **Axios** for API calls
- **Socket.io** for real-time features

#### Backend
- **Node.js** with Express.js
- **TypeScript** for type safety
- **MongoDB** with Mongoose ODM
- **Redis** for caching and sessions
- **JWT** for authentication
- **bcrypt** for password hashing

#### DevOps & Infrastructure
- **Docker** for containerization
- **Kubernetes** for orchestration
- **Terraform** for infrastructure as code
- **Jenkins** for CI/CD pipeline
- **Helm** for package management
- **Istio** for service mesh

#### Monitoring & Security
- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Datadog** for APM and logs
- **Jaeger** for distributed tracing
- **SonarQube** for code quality
- **OWASP ZAP** for security testing

## 📋 Prerequisites

### System Requirements
- **Node.js**: 18.0.0 or higher
- **Docker**: 20.10.0 or higher
- **Kubernetes**: 1.19.0 or higher
- **Terraform**: 1.0.0 or higher
- **kubectl**: Configured for your cluster

### Development Setup
\`\`\`bash
# Clone repository
git clone https://github.com/arsh-dang/healthcare-devops-pipeline.git
cd healthcare-devops-pipeline

# Install dependencies
npm install

# Start development environment
docker-compose up -d

# Run application
npm run dev
\`\`\`

## 🚀 Deployment

### Quick Start
\`\`\`bash
# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh production
\`\`\`

### Blue-Green Deployment
\`\`\`bash
# Deploy new version to green environment
./scripts/production-deploy.sh production v1.2.3

# Verify deployment
curl https://api.healthcare-app.com/health
\`\`\`

### Canary Deployment
\`\`\`bash
# Start canary deployment
kubectl apply -f k8s/canary/

# Monitor canary metrics
kubectl get pods -l environment=canary
\`\`\`

## 📊 Monitoring

### Access Monitoring Interfaces

#### Grafana Dashboards
\`\`\`bash
kubectl port-forward svc/grafana 3000:3000
# Access: http://localhost:30285
\`\`\`

#### Prometheus Metrics
\`\`\`bash
kubectl port-forward svc/prometheus 9090:9090
# Access: http://localhost:30285/prometheus
\`\`\`

#### Jaeger Tracing
\`\`\`bash
kubectl port-forward svc/jaeger 16686:16686
# Access: http://localhost:30285/jaeger
\`\`\`

### Key Metrics
- **Application Performance**: Response times, error rates, throughput
- **Infrastructure Health**: CPU, memory, disk usage
- **Business Metrics**: User registrations, appointment bookings
- **Security Events**: Failed authentication attempts, suspicious activities

## 🧪 Testing

### Run Test Suite
\`\`\`bash
# Unit tests
npm run test:unit

# Integration tests
npm run test:integration

# End-to-end tests
npm run test:e2e

# Load testing
./scripts/load-testing.sh

# Chaos engineering
./scripts/chaos-engineering.sh
\`\`\`

### Test Coverage
- **Unit Tests**: 90%+ coverage
- **Integration Tests**: API endpoints and database operations
- **E2E Tests**: Complete user workflows
- **Performance Tests**: Load testing with Artillery
- **Security Tests**: Automated vulnerability scanning

## 🔒 Security

### Security Features
- **Authentication**: JWT with refresh tokens
- **Authorization**: Role-based access control
- **Data Encryption**: TLS 1.3, AES-256 encryption
- **Security Headers**: OWASP recommended headers
- **Rate Limiting**: API rate limiting and DDoS protection
- **Audit Logging**: Comprehensive security event logging

### Security Scanning
\`\`\`bash
# Run security scan
./scripts/advanced-security-scan.sh

# View security reports
open security-reports/
\`\`\`

## 📚 API Documentation

### OpenAPI Specification
The API is fully documented using OpenAPI 3.0 specification.

\`\`\`bash
# Generate API docs
./scripts/generate-docs.sh

# View API documentation
open docs/generated/api/index.html
\`\`\`

### Key Endpoints

#### Authentication
- \`POST /api/auth/login\` - User login
- \`POST /api/auth/register\` - User registration
- \`POST /api/auth/refresh\` - Refresh access token

#### Patients
- \`GET /api/patients\` - List patients
- \`POST /api/patients\` - Create patient
- \`GET /api/patients/:id\` - Get patient details
- \`PUT /api/patients/:id\` - Update patient
- \`DELETE /api/patients/:id\` - Delete patient

#### Appointments
- \`GET /api/appointments\` - List appointments
- \`POST /api/appointments\` - Create appointment
- \`GET /api/appointments/:id\` - Get appointment details
- \`PUT /api/appointments/:id\` - Update appointment
- \`DELETE /api/appointments/:id\` - Delete appointment

## 🤝 Contributing

### Development Workflow
1. **Fork** the repository
2. **Create** a feature branch (\`git checkout -b feature/amazing-feature\`)
3. **Commit** your changes (\`git commit -m 'Add amazing feature'\`)
4. **Push** to the branch (\`git push origin feature/amazing-feature\`)
5. **Open** a Pull Request

### Code Standards
- **ESLint**: JavaScript/TypeScript linting
- **Prettier**: Code formatting
- **Husky**: Git hooks for quality checks
- **Commitizen**: Standardized commit messages

### Testing Requirements
- All new features must include unit tests
- Integration tests for API changes
- E2E tests for user-facing features
- 90%+ code coverage requirement

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Healthcare Domain Experts**: For medical workflow insights
- **DevOps Community**: For best practices and tools
- **Open Source Contributors**: For amazing tools and libraries
- **Security Researchers**: For vulnerability research and tools

## 📞 Support

### Documentation
- [API Documentation](./docs/generated/api/)
- [Deployment Guide](./docs/generated/deployment-guide.md)
- [Architecture Overview](./docs/generated/architecture/)

### Getting Help
- **Issues**: [GitHub Issues](https://github.com/arsh-dang/healthcare-devops-pipeline/issues)
- **Discussions**: [GitHub Discussions](https://github.com/arsh-dang/healthcare-devops-pipeline/discussions)
- **Documentation**: [Wiki](https://github.com/arsh-dang/healthcare-devops-pipeline/wiki)

### Community
- **Slack**: Join our [Slack community](https://healthcare-devops.slack.com)
- **Twitter**: Follow [@HealthcareDevOps](https://twitter.com/HealthcareDevOps)
- **Blog**: [DevOps Blog](https://blog.healthcare-devops.com)

---

**Built with ❤️ for healthcare professionals worldwide**
EOF

    log_success "Comprehensive README generated"
}

# Generate all documentation
generate_openapi_spec
generate_jsdoc
generate_architecture_docs
generate_deployment_docs
generate_readme

# Create documentation index
cat > $OUTPUT_DIR/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Healthcare DevOps Pipeline - Documentation</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            text-align: center;
            padding: 40px 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .card {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }
        .card:hover {
            transform: translateY(-5px);
        }
        .card h3 {
            color: #667eea;
            margin-top: 0;
        }
        .btn {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 10px 20px;
            text-decoration: none;
            border-radius: 5px;
            margin: 5px;
            transition: background 0.2s;
        }
        .btn:hover {
            background: #5a6fd8;
        }
        .status {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: bold;
        }
        .status.generated {
            background: #d4edda;
            color: #155724;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🏥 Healthcare DevOps Pipeline</h1>
        <p>Comprehensive Documentation Suite</p>
        <p><strong>Generated:</strong> $(date)</p>
        <p><strong>Version:</strong> $VERSION</p>
    </div>

    <div class="grid">
        <div class="card">
            <h3>📚 API Documentation</h3>
            <p>OpenAPI 3.0 specification and interactive API documentation</p>
            <a href="api/openapi-spec.yaml" class="btn">OpenAPI Spec</a>
            <a href="api/jsdoc/index.html" class="btn">JSDoc</a>
            <span class="status generated">Generated</span>
        </div>

        <div class="card">
            <h3>🏗️ Architecture</h3>
            <p>System architecture, deployment strategies, and infrastructure design</p>
            <a href="architecture/system-overview.md" class="btn">System Overview</a>
            <a href="architecture/deployment-architecture.md" class="btn">Deployment</a>
            <span class="status generated">Generated</span>
        </div>

        <div class="card">
            <h3>🚀 Deployment Guide</h3>
            <p>Step-by-step deployment instructions and troubleshooting</p>
            <a href="deployment-guide.md" class="btn">Deployment Guide</a>
            <span class="status generated">Generated</span>
        </div>

        <div class="card">
            <h3>📖 Project README</h3>
            <p>Comprehensive project documentation and getting started guide</p>
            <a href="README.md" class="btn">View README</a>
            <span class="status generated">Generated</span>
        </div>
    </div>

    <div class="card" style="margin-top: 30px;">
        <h3>📊 Documentation Summary</h3>
        <ul>
            <li><strong>API Documentation:</strong> OpenAPI spec, JSDoc, interactive docs</li>
            <li><strong>Architecture Docs:</strong> System design, deployment strategies</li>
            <li><strong>Deployment Guide:</strong> Installation, configuration, troubleshooting</li>
            <li><strong>Project README:</strong> Overview, features, getting started</li>
            <li><strong>Generated Files:</strong> $(find $OUTPUT_DIR -type f | wc -l) files</li>
            <li><strong>Total Size:</strong> $(du -sh $OUTPUT_DIR | cut -f1)</li>
        </ul>
    </div>

    <div style="text-align: center; margin-top: 40px; color: #666;">
        <p>Generated by Enhanced Documentation Generator v1.0</p>
        <p>For questions or issues, please refer to the project repository</p>
    </div>
</body>
</html>
EOF

log_success "Documentation index generated"
log_docs "Documentation generation completed!"
log_info "Generated files:"
find $OUTPUT_DIR -type f | while read file; do
    log_info "  - $file"
done

log_info "Total files generated: $(find $OUTPUT_DIR -type f | wc -l)"
log_info "Total size: $(du -sh $OUTPUT_DIR | cut -f1)"
log_info ""
log_info "📖 Open documentation index:"
log_info "   open $OUTPUT_DIR/index.html"
