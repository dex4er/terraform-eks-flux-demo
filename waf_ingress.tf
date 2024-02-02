## WAF for ALB for cluster ingress.

locals {
  waf_block_regions = {
    ## ISO-3166-1 = ["ISO-3166-2", ...]
    DE = ["BE"]
    FR = []
    PL = ["02", "14"]
    RU = []
  }
}

resource "aws_wafv2_rule_group" "block-countries-and-regions" {
  name        = "block-countries-and-regions"
  description = "Blocks traffic from chosen ISO-3166-1 countries and ISO-3166-2 regions"
  scope       = "REGIONAL"
  capacity    = 2 + sum([for k, v in local.waf_block_regions : length(v)])

  dynamic "rule" {
    for_each = toset(length([for k, v in local.waf_block_regions : true if length(v) == 0]) > 0 ? [1] : [])
    content {
      name     = "block-countries"
      priority = 1

      action {
        block {
          custom_response {
            response_code            = 418
            custom_response_body_key = "blocked"
            response_header {
              name  = "rule"
              value = "block-countries"
            }
          }
        }
      }

      statement {
        geo_match_statement {
          country_codes = [for k, v in local.waf_block_regions : k if length(v) == 0]
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "block-countries-and-regions-group-rule-block-countries"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = toset(length([for k, v in local.waf_block_regions : true if length(v) > 0]) > 0 ? [1] : [])
    content {
      name     = "count-countries"
      priority = 2

      action {
        count {}
      }

      statement {
        geo_match_statement {
          country_codes = [for k, v in local.waf_block_regions : k if length(v) > 0]
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "block-countries-and-regions-group-rule-count-countries"
        sampled_requests_enabled   = false
      }
    }
  }

  dynamic "rule" {
    for_each = toset(length([for k, v in local.waf_block_regions : true if length(v) > 0]) > 0 ? [1] : [])
    content {
      name     = "block-regions"
      priority = 3

      action {
        block {
          custom_response {
            response_code            = 418
            custom_response_body_key = "blocked"
            response_header {
              name  = "rule"
              value = "block-regions"
            }
          }
        }
      }

      statement {
        or_statement {
          dynamic "statement" {
            for_each = toset(flatten([for k, v in local.waf_block_regions : [for i in v : "${k}-${i}"] if length(v) > 0]))
            content {
              label_match_statement {
                scope = "LABEL"
                key   = "awswaf:clientip:geo:region:${statement.key}"
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "block-countries-and-regions-group-rule-block-regions"
        sampled_requests_enabled   = true
      }
    }
  }

  custom_response_body {
    key          = "blocked"
    content_type = "TEXT_PLAIN"
    content      = "Blocked"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "block-countries-and-regions-group"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl" "block-countries-and-regions" {
  name        = "block-countries-and-regions"
  description = "Blocks traffic from chosen ISO-3166-1 countries and ISO-3166-2 regions"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "block-countries-and-regions"
    priority = 1

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.block-countries-and-regions.arn
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "block-countries-and-regions-rule"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "block-countries-and-regions-acl"
    sampled_requests_enabled   = false
  }
}

locals {
  wafv2_acl_arn = aws_wafv2_web_acl.block-countries-and-regions.arn
}

resource "aws_cloudwatch_log_group" "block-countries-and-regions" {
  name = "aws-waf-logs-block-countries-and-regions"
}

resource "aws_wafv2_web_acl_logging_configuration" "block-countries-and-regions" {
  log_destination_configs = [aws_cloudwatch_log_group.block-countries-and-regions.arn]
  resource_arn            = local.wafv2_acl_arn

  logging_filter {
    default_behavior = "KEEP"

    filter {
      behavior = "DROP"

      condition {
        action_condition {
          action = "ALLOW"
        }
      }

      condition {
        action_condition {
          action = "COUNT"
        }
      }

      requirement = "MEETS_ANY"
    }
  }
}

## It is enabled by annotation for Ingress
# resource "aws_wafv2_web_acl_association" "ingress-block-countries-and-regions" {
#   resource_arn = aws_lb.ingress.arn
#   web_acl_arn  = local.wafv2_acl_arn
# }
