# IAM Access Analyzer
# Provides a simple security audit for IAM roles and policies.

resource "aws_accessanalyzer_analyzer" "main" {
  analyzer_name = "${var.project}-${var.environment}-access-analyzer"
  type          = "ACCOUNT"

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}
