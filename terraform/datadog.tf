# =============================================================================
# DATADOG CLOUD INTEGRATION - INFRASTRUCTURE AS CODE
# =============================================================================

# =============================================================================
# DATADOG DASHBOARDS
# =============================================================================

# Healthcare Application Dashboard
resource "datadog_dashboard" "healthcare_app_dashboard" {
  count = var.enable_datadog ? 1 : 0

  title       = "Healthcare Application - Comprehensive Monitoring"
  description = "Complete monitoring dashboard for healthcare application with business metrics, infrastructure monitoring, and performance tracking"
  layout_type = "ordered"

  widget {
    query_value_definition {
      title = "Application Health Overview"
      title_size = "16"
      title_align = "left"
      request {
        q = "avg:healthcare.app.health{*}"
        aggregator = "avg"
        conditional_formats {
          comparator = "<"
          value = 1
          palette = "red_on_white"
        }
        conditional_formats {
          comparator = ">="
          value = 1
          palette = "green_on_white"
        }
      }
      autoscale = true
      precision = 2
      text_align = "center"
    }
  }

  widget {
    timeseries_definition {
      title = "Request Rate (per second)"
      title_size = "16"
      title_align = "left"
      request {
        q = "rate(healthcare.api.requests{*}[1m])"
        display_type = "line"
        style {
          palette = "dog_classic"
          line_type = "solid"
          line_width = "normal"
        }
      }
      yaxis {
        label = "Requests/sec"
        scale = "linear"
        min = "0"
      }
      show_legend = false
    }
  }

  widget {
    timeseries_definition {
      title = "Response Time (95th percentile)"
      title_size = "16"
      title_align = "left"
      request {
        q = "avg:healthcare.api.response_time{*}.rollup(avg, 60)"
        display_type = "line"
        style {
          palette = "dog_classic"
          line_type = "solid"
          line_width = "normal"
        }
      }
      yaxis {
        label = "ms"
        scale = "linear"
        min = "0"
      }
      show_legend = false
    }
  }

  widget {
    timeseries_definition {
      title = "Error Rate"
      title_size = "16"
      title_align = "left"
      request {
        q = "rate(healthcare.api.errors{*}[1m]) / rate(healthcare.api.requests{*}[1m]) * 100"
        display_type = "line"
        style {
          palette = "red"
          line_type = "solid"
          line_width = "normal"
        }
      }
      yaxis {
        label = "%"
        scale = "linear"
        min = "0"
        max = "100"
      }
      show_legend = false
    }
  }

  widget {
    timeseries_definition {
      title = "Database Performance"
      title_size = "16"
      title_align = "left"
      request {
        q = "avg:mongodb.connections.current{*}"
        display_type = "line"
        style {
          palette = "dog_classic"
          line_type = "solid"
          line_width = "normal"
        }
      }
      request {
        q = "avg:mongodb.operations.rate{*}"
        display_type = "line"
        style {
          palette = "green"
          line_type = "solid"
          line_width = "normal"
        }
      }
      yaxis {
        label = "Count"
        scale = "linear"
      }
      show_legend = true
    }
  }

  widget {
    timeseries_definition {
      title = "Infrastructure Metrics"
      title_size = "16"
      title_align = "left"
      request {
        q = "avg:system.cpu.user{*}"
        display_type = "line"
        style {
          palette = "dog_classic"
          line_type = "solid"
          line_width = "normal"
        }
      }
      request {
        q = "avg:system.mem.used{*}"
        display_type = "line"
        style {
          palette = "orange"
          line_type = "solid"
          line_width = "normal"
        }
      }
      yaxis {
        label = "%"
        scale = "linear"
        min = "0"
        max = "100"
      }
      show_legend = true
    }
  }

  widget {
    query_value_definition {
      title = "Business Metrics"
      title_size = "16"
      title_align = "left"
      request {
        q = "sum:healthcare.patients.active{*}"
        aggregator = "sum"
        conditional_formats {
          comparator = ">"
          value = 1000
          palette = "green_on_white"
        }
        conditional_formats {
          comparator = "<="
          value = 1000
          palette = "yellow_on_white"
        }
      }
      autoscale = true
      precision = 0
      text_align = "center"
    }
  }

  widget {
    toplist_definition {
      title = "API Endpoint Performance"
      title_size = "16"
      title_align = "left"
      request {
        q = "top(avg:healthcare.api.response_time{*} by {endpoint}, 10, 'mean', 'desc')"
        style {
          palette = "dog_classic_area"
        }
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Security Events"
      title_size = "16"
      title_align = "left"
      request {
        q = "sum:healthcare.security.failed_logins{*}.as_count()"
        display_type = "bars"
        style {
          palette = "red"
          line_type = "solid"
          line_width = "normal"
        }
      }
      yaxis {
        label = "Events"
        scale = "linear"
      }
      show_legend = false
    }
  }

  widget {
    query_value_definition {
      title = "Deployment Status"
      title_size = "16"
      title_align = "left"
      request {
        q = "avg:healthcare.deployment.status{*}"
        aggregator = "avg"
        conditional_formats {
          comparator = "="
          value = 1
          palette = "green_on_white"
        }
        conditional_formats {
          comparator = "="
          value = 0
          palette = "red_on_white"
        }
      }
      autoscale = true
      precision = 0
      text_align = "center"
    }
  }

  widget {
    timeseries_definition {
      title = "Log Volume by Service"
      title_size = "16"
      title_align = "left"
      request {
        q = "sum:healthcare.logs.count{*} by {service}.as_count()"
        display_type = "area"
        style {
          palette = "dog_classic_area"
          line_type = "solid"
          line_width = "normal"
        }
      }
      yaxis {
        label = "Logs/min"
        scale = "linear"
      }
      show_legend = true
    }
  }

  widget {
    query_value_definition {
      title = "SLA Compliance"
      title_size = "16"
      title_align = "left"
      request {
        q = "avg:healthcare.sla.uptime{*}"
        aggregator = "avg"
        conditional_formats {
          comparator = ">="
          value = 99.9
          palette = "green_on_white"
        }
        conditional_formats {
          comparator = ">="
          value = 99.0
          palette = "yellow_on_white"
        }
        conditional_formats {
          comparator = "<"
          value = 99.0
          palette = "red_on_white"
        }
      }
      autoscale = true
      precision = 2
      text_align = "center"
    }
  }

  template_variable {
    name = "environment"
    default = var.environment
    available_values = ["staging", "production"]
    prefix = "env"
  }

  template_variable {
    name = "service"
    default = "*"
    available_values = ["frontend", "backend", "database"]
    prefix = "service"
  }

  tags = ["healthcare", "monitoring", "api", "infrastructure", "terraform"]
}

# Jenkins CI/CD Dashboard
resource "datadog_dashboard" "jenkins_cicd_dashboard" {
  count = var.enable_datadog ? 1 : 0

  title       = "Healthcare App - Jenkins CI/CD Pipeline"
  description = "Jenkins pipeline monitoring and metrics for healthcare application"
  layout_type = "ordered"

  widget {
    timeseries_definition {
      title = "Pipeline Execution Time"
      title_size = "16"
      title_align = "left"
      request {
        q = "avg:jenkins.build.duration{*} by {stage}"
        display_type = "line"
        style {
          palette = "dog_classic"
          line_type = "solid"
          line_width = "normal"
        }
      }
      yaxis {
        label = "Seconds"
        scale = "linear"
        min = "0"
      }
      show_legend = true
    }
  }

  widget {
    timeseries_definition {
      title = "Test Results"
      title_size = "16"
      title_align = "left"
      request {
        q = "avg:jenkins.tests.passed{*}"
        display_type = "line"
        style {
          palette = "green"
          line_type = "solid"
          line_width = "normal"
        }
      }
      request {
        q = "avg:jenkins.tests.failed{*}"
        display_type = "line"
        style {
          palette = "red"
          line_type = "solid"
          line_width = "normal"
        }
      }
      yaxis {
        label = "Tests"
        scale = "linear"
        min = "0"
      }
      show_legend = true
    }
  }

  widget {
    query_value_definition {
      title = "Deployment Success Rate"
      title_size = "16"
      title_align = "left"
      request {
        q = "avg:jenkins.deployment.status{*}"
        aggregator = "avg"
        conditional_formats {
          comparator = ">="
          value = 0.9
          palette = "green_on_white"
        }
        conditional_formats {
          comparator = ">="
          value = 0.7
          palette = "yellow_on_white"
        }
        conditional_formats {
          comparator = "<"
          value = 0.7
          palette = "red_on_white"
        }
      }
      autoscale = true
      precision = 2
      text_align = "center"
    }
  }

  widget {
    query_value_definition {
      title = "Pipeline Health"
      title_size = "16"
      title_align = "left"
      request {
        q = "avg:jenkins.build.status{*}"
        aggregator = "avg"
        conditional_formats {
          comparator = "="
          value = 1
          palette = "green_on_white"
        }
        conditional_formats {
          comparator = "="
          value = 0
          palette = "red_on_white"
        }
      }
      autoscale = true
      precision = 0
      text_align = "center"
    }
  }

  template_variable {
    name = "environment"
    default = var.environment
    available_values = ["staging", "production"]
    prefix = "env"
  }

  template_variable {
    name = "branch"
    default = "*"
    available_values = ["main", "develop", "feature/*"]
    prefix = "branch"
  }

  tags = ["healthcare", "jenkins", "ci-cd", "pipeline", "terraform"]
}

# =============================================================================
# DATADOG MONITORS (ALERTS)
# =============================================================================

# High Error Rate Monitor
resource "datadog_monitor" "healthcare_high_error_rate" {
  count = var.enable_datadog ? 1 : 0

  name               = "Healthcare App - High Error Rate"
  type               = "metric alert"
  message            = "Healthcare application error rate is above 5% for more than 5 minutes. This indicates potential issues with the application that require immediate attention. @slack-healthcare-alerts"
  escalation_message = "Healthcare app error rate remains high. Escalating to on-call engineer."

  query = "avg(last_5m):avg:healthcare.api.errors{*} / avg:healthcare.api.requests{*} * 100 > 5"

  monitor_thresholds {
    warning  = 2
    critical = 5
  }

  notify_no_data    = false
  no_data_timeframe = 10
  renotify_interval = 0
  require_full_window = true
  new_group_delay   = 300
  new_group_delay   = 300

  tags = ["healthcare", "api", "error-rate", "critical", "terraform"]
  priority = 1
}

# High Response Time Monitor
resource "datadog_monitor" "healthcare_high_response_time" {
  count = var.enable_datadog ? 1 : 0

  name    = "Healthcare App - High Response Time"
  type    = "metric alert"
  message = "Healthcare application response time (95th percentile) is above 2 seconds for more than 10 minutes. This may impact user experience. @slack-healthcare-alerts"

  query = "avg(last_10m):avg:healthcare.api.response_time{*}.rollup(avg, 300) > 2000"

  monitor_thresholds {
    warning  = 2000
    critical = 5000
  }

  notify_no_data    = false
  no_data_timeframe = 20
  renotify_interval = 30
  require_full_window = true
  new_group_delay   = 300
  new_group_delay   = 300

  tags = ["healthcare", "api", "performance", "warning", "terraform"]
  priority = 2
}

# Database Connection Issues Monitor
resource "datadog_monitor" "healthcare_database_connections" {
  count = var.enable_datadog ? 1 : 0

  name    = "Healthcare App - Database Connection Issues"
  type    = "metric alert"
  message = "MongoDB connection count is above 80% of maximum connections. Database may be under stress. @slack-healthcare-alerts"

  query = "avg(last_5m):avg:mongodb.connections.current{*} / avg:mongodb.connections.available{*} * 100 > 80"

  monitor_thresholds {
    warning  = 80
    critical = 95
  }

  notify_no_data    = false
  no_data_timeframe = 10
  renotify_interval = 60
  require_full_window = true
  new_group_delay   = 300
  new_group_delay   = 300

  tags = ["healthcare", "database", "mongodb", "connections", "terraform"]
  priority = 2
}

# High CPU Usage Monitor
resource "datadog_monitor" "healthcare_high_cpu" {
  count = var.enable_datadog ? 1 : 0

  name    = "Healthcare App - High CPU Usage"
  type    = "metric alert"
  message = "Healthcare application CPU usage is above 80% for more than 15 minutes. System may be under stress. @slack-healthcare-alerts"

  query = "avg(last_15m):avg:system.cpu.user{*} > 80"

  monitor_thresholds {
    warning  = 80
    critical = 90
  }

  notify_no_data    = false
  no_data_timeframe = 20
  renotify_interval = 60
  require_full_window = true
  new_group_delay   = 300
  new_group_delay   = 300

  tags = ["healthcare", "infrastructure", "cpu", "performance", "terraform"]
  priority = 3
}

# High Memory Usage Monitor
resource "datadog_monitor" "healthcare_high_memory" {
  count = var.enable_datadog ? 1 : 0

  name    = "Healthcare App - High Memory Usage"
  type    = "metric alert"
  message = "Healthcare application memory usage is above 85% for more than 10 minutes. System may need attention. @slack-healthcare-alerts"

  query = "avg(last_10m):avg:system.mem.used{*} / avg:system.mem.total{*} * 100 > 85"

  monitor_thresholds {
    warning  = 85
    critical = 95
  }

  notify_no_data    = false
  no_data_timeframe = 15
  renotify_interval = 60
  require_full_window = true
  new_group_delay   = 300
  new_group_delay   = 300

  tags = ["healthcare", "infrastructure", "memory", "performance", "terraform"]
  priority = 3
}

# Service Unavailable Monitor
resource "datadog_monitor" "healthcare_service_unavailable" {
  count = var.enable_datadog ? 1 : 0

  name               = "Healthcare App - Service Unavailable"
  type               = "metric alert"
  message            = "Healthcare application health check is failing. Service may be down. @slack-healthcare-critical"
  escalation_message = "Healthcare service is down. Immediate action required."

  query = "avg(last_2m):avg:healthcare.app.health{*} < 1"

  monitor_thresholds {
    warning  = 0.8
    critical = 1
  }

  notify_audit       = true
  notify_no_data     = true
  no_data_timeframe  = 2
  renotify_interval  = 10
  require_full_window = false
  new_group_delay    = 300
  new_host_delay     = 300

  tags = ["healthcare", "availability", "critical", "service-down", "terraform"]
  priority = 1
}

# Security Events Monitor
resource "datadog_monitor" "healthcare_security_events" {
  count = var.enable_datadog ? 1 : 0

  name    = "Healthcare App - Security Events"
  type    = "metric alert"
  message = "Unusual security activity detected. Multiple failed login attempts or suspicious behavior. @slack-healthcare-security"

  query = "sum(last_5m):sum:healthcare.security.failed_logins{*}.as_count() > 10"

  monitor_thresholds {
    warning  = 10
    critical = 50
  }

  notify_audit      = true
  notify_no_data    = false
  no_data_timeframe = 10
  renotify_interval = 30
  require_full_window = true
  new_group_delay   = 300
  new_group_delay   = 300

  tags = ["healthcare", "security", "failed-logins", "threat-detection", "terraform"]
  priority = 2
}

# SLA Breach Monitor
resource "datadog_monitor" "healthcare_sla_breach" {
  count = var.enable_datadog ? 1 : 0

  name    = "Healthcare App - SLA Breach"
  type    = "metric alert"
  message = "Healthcare application SLA is below 99.9% uptime. This may impact service level agreements. @slack-healthcare-alerts"

  query = "avg(last_1h):avg:healthcare.sla.uptime{*} < 99.9"

  monitor_thresholds {
    warning  = 99.9
    critical = 99.0
  }

  notify_audit      = true
  notify_no_data    = false
  no_data_timeframe = 30
  renotify_interval = 120
  require_full_window = true
  new_group_delay   = 300
  new_group_delay   = 300

  tags = ["healthcare", "sla", "uptime", "business-impact", "terraform"]
  priority = 2
}

# Deployment Failure Monitor
resource "datadog_monitor" "healthcare_deployment_failure" {
  count = var.enable_datadog ? 1 : 0

  name    = "Healthcare App - Deployment Failure"
  type    = "metric alert"
  message = "Healthcare application deployment has failed or is stuck. New version may not be deployed properly. @slack-healthcare-alerts"

  query = "avg(last_10m):avg:healthcare.deployment.status{*} < 1"

  monitor_thresholds {
    warning  = 1
    critical = 0.5
  }

  notify_no_data    = false
  no_data_timeframe = 15
  renotify_interval = 60
  require_full_window = true
  new_group_delay   = 300
  new_group_delay   = 300

  tags = ["healthcare", "deployment", "ci-cd", "release", "terraform"]
  priority = 2
}

# Jenkins Pipeline Failure Monitor
resource "datadog_monitor" "jenkins_pipeline_failure" {
  count = var.enable_datadog ? 1 : 0

  name    = "Jenkins Pipeline - Build Failure"
  type    = "metric alert"
  message = "Jenkins pipeline build has failed. CI/CD process requires attention. @slack-healthcare-alerts"

  query = "avg(last_5m):avg:jenkins.build.status{*} < 1"

  monitor_thresholds {
    warning  = 1
    critical = 0.5
  }

  notify_no_data    = false
  no_data_timeframe = 10
  renotify_interval = 30
  require_full_window = true
  new_group_delay   = 300
  new_group_delay   = 300

  tags = ["healthcare", "jenkins", "ci-cd", "build-failure", "terraform"]
  priority = 2
}

# =============================================================================
# DATADOG SYNTHETIC TESTS
# =============================================================================

# API Health Check Synthetic Test
resource "datadog_synthetics_test" "healthcare_api_health_check" {
  count = var.enable_datadog ? 1 : 0

  type    = "api"
  subtype = "http"
  name    = "Healthcare API Health Check"
  message = "Healthcare API health check failed. @slack-healthcare-critical"
  tags    = ["healthcare", "api", "health-check", "terraform"]

  locations = ["aws:us-east-1", "aws:us-west-2"]

  status = "live"

  request_definition {
    method = "GET"
    url    = var.environment == "production" ? "https://healthcare.company.com/api/health" : "http://localhost:32713/api/health"
    timeout = 30
  }

  assertion {
    type     = "statusCode"
    operator = "is"
    target   = "200"
  }

  assertion {
    type     = "responseTime"
    operator = "lessThan"
    target   = 2000
  }

  options_list {
    tick_every = 60
    retry {
      count    = 3
      interval = 300
    }
    monitor_options {
      renotify_interval = 120
    }
  }
}

# Frontend Availability Synthetic Test
resource "datadog_synthetics_test" "healthcare_frontend_availability" {
  count = var.enable_datadog ? 1 : 0

  type    = "browser"
  name    = "Healthcare Frontend Availability"
  message = "Healthcare frontend is not accessible. @slack-healthcare-critical"
  tags    = ["healthcare", "frontend", "availability", "terraform"]

  locations = ["aws:us-east-1"]

  status = "live"

  request_definition {
    method = "GET"
    url    = var.environment == "production" ? "https://healthcare.company.com" : "http://localhost:32712"
  }

  assertion {
    type     = "statusCode"
    operator = "is"
    target   = "200"
  }

  options_list {
    tick_every = 300
    retry {
      count    = 2
      interval = 300
    }
    monitor_options {
      renotify_interval = 120
    }
  }
}

# =============================================================================
# DATADOG OUTPUTS
# =============================================================================

output "datadog_dashboard_url" {
  description = "URL of the healthcare application dashboard"
  value       = var.enable_datadog ? datadog_dashboard.healthcare_app_dashboard[0].url : null
}

output "datadog_jenkins_dashboard_url" {
  description = "URL of the Jenkins CI/CD dashboard"
  value       = var.enable_datadog ? datadog_dashboard.jenkins_cicd_dashboard[0].url : null
}

output "datadog_monitors_count" {
  description = "Number of Datadog monitors created"
  value       = var.enable_datadog ? 10 : 0
}

output "datadog_synthetic_tests_count" {
  description = "Number of Datadog synthetic tests created"
  value       = var.enable_datadog ? 2 : 0
}
