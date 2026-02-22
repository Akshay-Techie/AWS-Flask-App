#!/bin/bash

###############################################################################
# CloudWatch Agent Configuration Script
# This script installs and configures CloudWatch agent on EKS nodes
# Usage: ./cloudwatch-config.sh [ACTION]
# Example: ./cloudwatch-config.sh install
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
AWS_REGION="${AWS_REGION:-ap-south-1}"
LOG_GROUP_NAME="/aws/eks/project03-cluster"
CONFIG_PATH="/opt/aws/amazon-cloudwatch-agent/etc"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   CloudWatch Agent Configuration${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ This script must be run as root${NC}"
    exit 1
fi

# Function: Install CloudWatch Agent
install_agent() {
    echo -e "${YELLOW}Installing CloudWatch Agent...${NC}"
    
    # Download agent
    cd /tmp
    wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    
    # Install
    dpkg -i -E ./amazon-cloudwatch-agent.deb
    
    echo -e "${GREEN}✅ CloudWatch Agent installed${NC}"
}

# Function: Create config file
create_config() {
    echo -e "${YELLOW}Creating CloudWatch Agent configuration...${NC}"
    
    mkdir -p "$CONFIG_PATH"
    
    cat > "$CONFIG_PATH/cloudwatch-config.json" << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "region": "ap-south-1"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/containers/*.log",
            "log_group_name": "/aws/eks/project03-cluster",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S.%f%z"
          },
          {
            "file_path": "/var/log/pods/*/*.log",
            "log_group_name": "/aws/eks/project03-cluster/pods",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/eks/project03-cluster/system",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
      "ImageId": "${aws:ImageId}",
      "InstanceId": "${aws:InstanceId}",
      "InstanceType": "${aws:InstanceType}"
    },
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_USAGE_IDLE",
            "unit": "Percent"
          },
          {
            "name": "cpu_usage_iowait",
            "rename": "CPU_USAGE_IOWAIT",
            "unit": "Percent"
          },
          "cpu_time_guest"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ],
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED_PERCENT",
            "unit": "Percent"
          },
          {
            "name": "free",
            "rename": "DISK_FREE",
            "unit": "Gigabytes"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED_PERCENT",
            "unit": "Percent"
          },
          {
            "name": "mem_available",
            "rename": "MEM_AVAILABLE",
            "unit": "Megabytes"
          }
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          {
            "name": "tcp_established",
            "rename": "TCP_ESTABLISHED",
            "unit": "Count"
          },
          {
            "name": "tcp_time_wait",
            "rename": "TCP_TIME_WAIT",
            "unit": "Count"
          }
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          {
            "name": "swap_used_percent",
            "rename": "SWAP_USED_PERCENT",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF
    
    echo -e "${GREEN}✅ Configuration file created at: $CONFIG_PATH/cloudwatch-config.json${NC}"
}

# Function: Start CloudWatch Agent
start_agent() {
    echo -e "${YELLOW}Starting CloudWatch Agent...${NC}"
    
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -c "file:$CONFIG_PATH/cloudwatch-config.json" \
        -s
    
    echo -e "${GREEN}✅ CloudWatch Agent started${NC}"
}

# Function: Stop CloudWatch Agent
stop_agent() {
    echo -e "${YELLOW}Stopping CloudWatch Agent...${NC}"
    
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -m ec2 \
        -a stop
    
    echo -e "${GREEN}✅ CloudWatch Agent stopped${NC}"
}

# Function: Check agent status
status_agent() {
    echo -e "${YELLOW}CloudWatch Agent Status:${NC}"
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a query \
        -m ec2
}

# Function: View recent logs
view_logs() {
    echo -e "${YELLOW}Recent CloudWatch Logs:${NC}"
    aws logs tail "$LOG_GROUP_NAME" \
        --region "$AWS_REGION" \
        --follow \
        --max-items 100
}

# Main
ACTION="${1:-status}"

case "$ACTION" in
    install)
        install_agent
        echo ""
        create_config
        echo ""
        start_agent
        echo ""
        status_agent
        ;;
    config)
        create_config
        ;;
    start)
        start_agent
        ;;
    stop)
        stop_agent
        ;;
    status)
        status_agent
        ;;
    logs)
        view_logs
        ;;
    *)
        echo -e "${YELLOW}Usage: $0 [ACTION]${NC}"
        echo ""
        echo "Actions:"
        echo "  install  - Install and configure CloudWatch Agent"
        echo "  config   - Create configuration file only"
        echo "  start    - Start CloudWatch Agent"
        echo "  stop     - Stop CloudWatch Agent"
        echo "  status   - Check agent status"
        echo "  logs     - View recent logs in CloudWatch"
        echo ""
        echo "Examples:"
        echo "  sudo $0 install"
        echo "  sudo $0 status"
        echo "  $0 logs"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ CloudWatch configuration complete!${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "  View logs: aws logs tail $LOG_GROUP_NAME --region $AWS_REGION --follow"
echo "  Search errors: aws logs filter-log-events --log-group-name $LOG_GROUP_NAME --filter-pattern 'ERROR'"
echo "  Create metric filter: aws logs put-metric-filter ..."
echo "  Check agent status: sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a query -m ec2"
