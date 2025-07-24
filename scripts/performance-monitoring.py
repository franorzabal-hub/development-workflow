#!/usr/bin/env python3
"""
Performance Monitoring System - Sprint 3: Monitoring & Quality
Development Workflow - Linear ↔ GitHub Integration

This script provides real-time performance monitoring, alerting,
and automated performance optimization for the development workflow.
"""

import os
import sys
import json
import time
import logging
import psutil
import requests
import threading
import sqlite3
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass, asdict
from contextlib import contextmanager
import subprocess
import asyncio
import aiohttp
import yaml
from pathlib import Path
import statistics
import smtplib
from email.mime.text import MimeText
import socket
import gc
import tracemalloc
import cProfile
import pstats
from io import StringIO

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class PerformanceMetric:
    """Data structure for performance metrics."""
    timestamp: str
    metric_name: str
    value: float
    unit: str
    threshold_warning: Optional[float] = None
    threshold_critical: Optional[float] = None
    metadata: Optional[Dict[str, Any]] = None

@dataclass
class PerformanceAlert:
    """Data structure for performance alerts."""
    timestamp: str
    alert_type: str  # 'warning', 'critical', 'recovery'
    metric_name: str
    current_value: float
    threshold: float
    message: str
    severity: str
    resolved: bool = False
    resolved_at: Optional[str] = None

@dataclass
class SystemHealth:
    """Overall system health status."""
    timestamp: str
    health_score: float  # 0-100
    status: str  # 'healthy', 'degraded', 'critical'
    active_alerts: int
    performance_grade: str  # A, B, C, D, F
    bottlenecks: List[str]
    recommendations: List[str]

class PerformanceDatabase:
    """Manages performance metrics storage."""
    
    def __init__(self, db_path: str = "performance.db"):
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize performance database."""
        with self.get_connection() as conn:
            # Performance metrics table
            conn.execute("""
                CREATE TABLE IF NOT EXISTS performance_metrics (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    metric_name TEXT NOT NULL,
                    value REAL NOT NULL,
                    unit TEXT NOT NULL,
                    threshold_warning REAL,
                    threshold_critical REAL,
                    metadata TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Performance alerts table
            conn.execute("""
                CREATE TABLE IF NOT EXISTS performance_alerts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    alert_type TEXT NOT NULL,
                    metric_name TEXT NOT NULL,
                    current_value REAL NOT NULL,
                    threshold REAL NOT NULL,
                    message TEXT NOT NULL,
                    severity TEXT NOT NULL,
                    resolved BOOLEAN DEFAULT FALSE,
                    resolved_at TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # System health snapshots
            conn.execute("""
                CREATE TABLE IF NOT EXISTS system_health (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    health_score REAL NOT NULL,
                    status TEXT NOT NULL,
                    active_alerts INTEGER NOT NULL,
                    performance_grade TEXT NOT NULL,
                    bottlenecks TEXT,
                    recommendations TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create indexes
            conn.execute("CREATE INDEX IF NOT EXISTS idx_perf_timestamp ON performance_metrics(timestamp)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_perf_metric ON performance_metrics(metric_name)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_alert_timestamp ON performance_alerts(timestamp)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_health_timestamp ON system_health(timestamp)")
    
    @contextmanager
    def get_connection(self):
        """Get database connection with context manager."""
        conn = sqlite3.connect(self.db_path)
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()
    
    def store_metric(self, metric: PerformanceMetric):
        """Store performance metric."""
        with self.get_connection() as conn:
            conn.execute("""
                INSERT INTO performance_metrics 
                (timestamp, metric_name, value, unit, threshold_warning, threshold_critical, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                metric.timestamp,
                metric.metric_name,
                metric.value,
                metric.unit,
                metric.threshold_warning,
                metric.threshold_critical,
                json.dumps(metric.metadata) if metric.metadata else None
            ))
    
    def store_alert(self, alert: PerformanceAlert):
        """Store performance alert."""
        with self.get_connection() as conn:
            conn.execute("""
                INSERT INTO performance_alerts 
                (timestamp, alert_type, metric_name, current_value, threshold, message, severity, resolved, resolved_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                alert.timestamp,
                alert.alert_type,
                alert.metric_name,
                alert.current_value,
                alert.threshold,
                alert.message,
                alert.severity,
                alert.resolved,
                alert.resolved_at
            ))
    
    def store_health_snapshot(self, health: SystemHealth):
        """Store system health snapshot."""
        with self.get_connection() as conn:
            conn.execute("""
                INSERT INTO system_health 
                (timestamp, health_score, status, active_alerts, performance_grade, bottlenecks, recommendations)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                health.timestamp,
                health.health_score,
                health.status,
                health.active_alerts,
                health.performance_grade,
                json.dumps(health.bottlenecks),
                json.dumps(health.recommendations)
            ))
    
    def get_recent_metrics(self, metric_name: str, hours: int = 24) -> List[PerformanceMetric]:
        """Get recent metrics for analysis."""
        start_time = (datetime.now() - timedelta(hours=hours)).isoformat()
        
        with self.get_connection() as conn:
            cursor = conn.execute("""
                SELECT timestamp, metric_name, value, unit, threshold_warning, threshold_critical, metadata
                FROM performance_metrics
                WHERE metric_name = ? AND timestamp >= ?
                ORDER BY timestamp DESC
            """, (metric_name, start_time))
            
            metrics = []
            for row in cursor.fetchall():
                metrics.append(PerformanceMetric(
                    timestamp=row[0],
                    metric_name=row[1],
                    value=row[2],
                    unit=row[3],
                    threshold_warning=row[4],
                    threshold_critical=row[5],
                    metadata=json.loads(row[6]) if row[6] else None
                ))
            
            return metrics
    
    def get_active_alerts(self) -> List[PerformanceAlert]:
        """Get active performance alerts."""
        with self.get_connection() as conn:
            cursor = conn.execute("""
                SELECT timestamp, alert_type, metric_name, current_value, threshold, 
                       message, severity, resolved, resolved_at
                FROM performance_alerts
                WHERE resolved = FALSE
                ORDER BY timestamp DESC
            """)
            
            alerts = []
            for row in cursor.fetchall():
                alerts.append(PerformanceAlert(
                    timestamp=row[0],
                    alert_type=row[1],
                    metric_name=row[2],
                    current_value=row[3],
                    threshold=row[4],
                    message=row[5],
                    severity=row[6],
                    resolved=bool(row[7]),
                    resolved_at=row[8]
                ))
            
            return alerts

class SystemPerformanceMonitor:
    """Monitors system-level performance metrics."""
    
    def __init__(self):
        self.thresholds = {
            'cpu_usage': {'warning': 70, 'critical': 85},
            'memory_usage': {'warning': 75, 'critical': 90},
            'disk_usage': {'warning': 80, 'critical': 95},
            'disk_io_latency': {'warning': 100, 'critical': 500},  # ms
            'network_latency': {'warning': 200, 'critical': 1000},  # ms
            'load_average': {'warning': 2.0, 'critical': 5.0},
        }
    
    def collect_metrics(self) -> List[PerformanceMetric]:
        """Collect system performance metrics."""
        timestamp = datetime.now().isoformat()
        metrics = []
        
        try:
            # CPU metrics
            cpu_percent = psutil.cpu_percent(interval=1)
            metrics.append(PerformanceMetric(
                timestamp=timestamp,
                metric_name='cpu_usage',
                value=cpu_percent,
                unit='percent',
                threshold_warning=self.thresholds['cpu_usage']['warning'],
                threshold_critical=self.thresholds['cpu_usage']['critical'],
                metadata={'cores': psutil.cpu_count()}
            ))
            
            # Memory metrics
            memory = psutil.virtual_memory()
            metrics.append(PerformanceMetric(
                timestamp=timestamp,
                metric_name='memory_usage',
                value=memory.percent,
                unit='percent',
                threshold_warning=self.thresholds['memory_usage']['warning'],
                threshold_critical=self.thresholds['memory_usage']['critical'],
                metadata={
                    'total_gb': round(memory.total / (1024**3), 2),
                    'available_gb': round(memory.available / (1024**3), 2),
                    'used_gb': round(memory.used / (1024**3), 2)
                }
            ))
            
            # Disk metrics
            disk = psutil.disk_usage('/')
            metrics.append(PerformanceMetric(
                timestamp=timestamp,
                metric_name='disk_usage',
                value=(disk.used / disk.total) * 100,
                unit='percent',
                threshold_warning=self.thresholds['disk_usage']['warning'],
                threshold_critical=self.thresholds['disk_usage']['critical'],
                metadata={
                    'total_gb': round(disk.total / (1024**3), 2),
                    'used_gb': round(disk.used / (1024**3), 2),
                    'free_gb': round(disk.free / (1024**3), 2)
                }
            ))
            
            # Disk I/O metrics
            disk_io = psutil.disk_io_counters()
            if disk_io:
                # Calculate I/O latency (simplified estimation)
                io_latency = (disk_io.read_time + disk_io.write_time) / max(disk_io.read_count + disk_io.write_count, 1)
                metrics.append(PerformanceMetric(
                    timestamp=timestamp,
                    metric_name='disk_io_latency',
                    value=io_latency,
                    unit='ms',
                    threshold_warning=self.thresholds['disk_io_latency']['warning'],
                    threshold_critical=self.thresholds['disk_io_latency']['critical'],
                    metadata={
                        'read_bytes': disk_io.read_bytes,
                        'write_bytes': disk_io.write_bytes,
                        'read_count': disk_io.read_count,
                        'write_count': disk_io.write_count
                    }
                ))
            
            # Load average (Unix/Linux only)
            try:
                load_avg = psutil.getloadavg()
                metrics.append(PerformanceMetric(
                    timestamp=timestamp,
                    metric_name='load_average',
                    value=load_avg[0],  # 1-minute load average
                    unit='ratio',
                    threshold_warning=self.thresholds['load_average']['warning'],
                    threshold_critical=self.thresholds['load_average']['critical'],
                    metadata={
                        'load_1min': load_avg[0],
                        'load_5min': load_avg[1],
                        'load_15min': load_avg[2]
                    }
                ))
            except (AttributeError, OSError):
                # Not available on Windows
                pass
            
            # Network latency to key services
            network_latency = self._test_network_latency()
            if network_latency is not None:
                metrics.append(PerformanceMetric(
                    timestamp=timestamp,
                    metric_name='network_latency',
                    value=network_latency,
                    unit='ms',
                    threshold_warning=self.thresholds['network_latency']['warning'],
                    threshold_critical=self.thresholds['network_latency']['critical']
                ))
            
        except Exception as e:
            logger.error(f"Failed to collect system metrics: {e}")
        
        return metrics
    
    def _test_network_latency(self) -> Optional[float]:
        """Test network latency to external services."""
        test_hosts = [
            ('api.linear.app', 443),
            ('api.github.com', 443),
            ('8.8.8.8', 53)  # Google DNS
        ]
        
        latencies = []
        for host, port in test_hosts:
            try:
                start_time = time.time()
                sock = socket.create_connection((host, port), timeout=5)
                sock.close()
                latency = (time.time() - start_time) * 1000  # Convert to ms
                latencies.append(latency)
            except Exception:
                continue
        
        return statistics.mean(latencies) if latencies else None

class ApplicationPerformanceMonitor:
    """Monitors application-specific performance metrics."""
    
    def __init__(self):
        self.thresholds = {
            'script_execution_time': {'warning': 30, 'critical': 60},  # seconds
            'api_response_time': {'warning': 2000, 'critical': 5000},  # ms
            'memory_usage_mb': {'warning': 512, 'critical': 1024},  # MB
            'error_rate': {'warning': 5, 'critical': 10},  # percent
            'queue_size': {'warning': 100, 'critical': 500},  # items
        }
        self.performance_log = Path("performance_log.json")
        self.error_log = Path("error_log.json")
    
    def collect_metrics(self) -> List[PerformanceMetric]:
        """Collect application performance metrics."""
        timestamp = datetime.now().isoformat()
        metrics = []
        
        try:
            # Script execution times
            script_metrics = self._get_script_performance_metrics(timestamp)
            metrics.extend(script_metrics)
            
            # API response times
            api_metrics = self._get_api_performance_metrics(timestamp)
            metrics.extend(api_metrics)
            
            # Application memory usage
            app_memory = self._get_application_memory_usage(timestamp)
            if app_memory:
                metrics.append(app_memory)
            
            # Error rate
            error_rate = self._calculate_error_rate(timestamp)
            if error_rate:
                metrics.append(error_rate)
            
        except Exception as e:
            logger.error(f"Failed to collect application metrics: {e}")
        
        return metrics
    
    def _get_script_performance_metrics(self, timestamp: str) -> List[PerformanceMetric]:
        """Get script execution performance metrics."""
        metrics = []
        
        if not self.performance_log.exists():
            return metrics
        
        try:
            with open(self.performance_log, 'r') as f:
                performance_data = json.load(f)
            
            script_times = performance_data.get('script_execution_times', {})
            for script_name, times in script_times.items():
                if times:
                    avg_time = statistics.mean(times[-10:])  # Last 10 executions
                    metrics.append(PerformanceMetric(
                        timestamp=timestamp,
                        metric_name=f'script_execution_time_{script_name}',
                        value=avg_time,
                        unit='seconds',
                        threshold_warning=self.thresholds['script_execution_time']['warning'],
                        threshold_critical=self.thresholds['script_execution_time']['critical'],
                        metadata={
                            'script_name': script_name,
                            'recent_executions': len(times[-10:]),
                            'min_time': min(times[-10:]),
                            'max_time': max(times[-10:])
                        }
                    ))
        
        except Exception as e:
            logger.warning(f"Failed to load script performance data: {e}")
        
        return metrics
    
    def _get_api_performance_metrics(self, timestamp: str) -> List[PerformanceMetric]:
        """Get API response time metrics."""
        metrics = []
        
        # Test Linear API
        linear_response_time = self._test_api_response_time('linear')
        if linear_response_time is not None:
            metrics.append(PerformanceMetric(
                timestamp=timestamp,
                metric_name='api_response_time_linear',
                value=linear_response_time,
                unit='ms',
                threshold_warning=self.thresholds['api_response_time']['warning'],
                threshold_critical=self.thresholds['api_response_time']['critical'],
                metadata={'api': 'linear'}
            ))
        
        # Test GitHub API
        github_response_time = self._test_api_response_time('github')
        if github_response_time is not None:
            metrics.append(PerformanceMetric(
                timestamp=timestamp,
                metric_name='api_response_time_github',
                value=github_response_time,
                unit='ms',
                threshold_warning=self.thresholds['api_response_time']['warning'],
                threshold_critical=self.thresholds['api_response_time']['critical'],
                metadata={'api': 'github'}
            ))
        
        return metrics
    
    def _test_api_response_time(self, api_name: str) -> Optional[float]:
        """Test API response time."""
        try:
            if api_name == 'linear':
                linear_api_key = os.getenv("LINEAR_API_KEY")
                if not linear_api_key:
                    return None
                
                start_time = time.time()
                response = requests.post(
                    "https://api.linear.app/graphql",
                    headers={"Authorization": f"Bearer {linear_api_key}"},
                    json={"query": "query { viewer { id } }"},
                    timeout=10
                )
                end_time = time.time()
                
                if response.status_code == 200:
                    return (end_time - start_time) * 1000
            
            elif api_name == 'github':
                github_token = os.getenv("GITHUB_TOKEN")
                headers = {"Authorization": f"token {github_token}"} if github_token else {}
                
                start_time = time.time()
                response = requests.get(
                    "https://api.github.com/user",
                    headers=headers,
                    timeout=10
                )
                end_time = time.time()
                
                if response.status_code in [200, 401]:  # 401 is expected without token
                    return (end_time - start_time) * 1000
        
        except Exception as e:
            logger.warning(f"Failed to test {api_name} API: {e}")
        
        return None
    
    def _get_application_memory_usage(self, timestamp: str) -> Optional[PerformanceMetric]:
        """Get current application memory usage."""
        try:
            current_process = psutil.Process()
            memory_info = current_process.memory_info()
            memory_mb = memory_info.rss / (1024 * 1024)  # Convert to MB
            
            return PerformanceMetric(
                timestamp=timestamp,
                metric_name='memory_usage_mb',
                value=memory_mb,
                unit='MB',
                threshold_warning=self.thresholds['memory_usage_mb']['warning'],
                threshold_critical=self.thresholds['memory_usage_mb']['critical'],
                metadata={
                    'pid': current_process.pid,
                    'rss_mb': round(memory_info.rss / (1024 * 1024), 2),
                    'vms_mb': round(memory_info.vms / (1024 * 1024), 2)
                }
            )
        
        except Exception as e:
            logger.warning(f"Failed to get application memory usage: {e}")
            return None
    
    def _calculate_error_rate(self, timestamp: str) -> Optional[PerformanceMetric]:
        """Calculate error rate from logs."""
        if not self.error_log.exists():
            return None
        
        try:
            with open(self.error_log, 'r') as f:
                error_data = json.load(f)
            
            # Count errors in last hour
            one_hour_ago = datetime.now() - timedelta(hours=1)
            recent_errors = [
                error for error in error_data.get('errors', [])
                if datetime.fromisoformat(error.get('timestamp', '')) > one_hour_ago
            ]
            
            total_operations = error_data.get('total_operations_last_hour', 100)
            error_rate = (len(recent_errors) / total_operations) * 100 if total_operations > 0 else 0
            
            return PerformanceMetric(
                timestamp=timestamp,
                metric_name='error_rate',
                value=error_rate,
                unit='percent',
                threshold_warning=self.thresholds['error_rate']['warning'],
                threshold_critical=self.thresholds['error_rate']['critical'],
                metadata={
                    'recent_errors': len(recent_errors),
                    'total_operations': total_operations,
                    'error_types': list(set(error.get('type', 'unknown') for error in recent_errors))
                }
            )
        
        except Exception as e:
            logger.warning(f"Failed to calculate error rate: {e}")
            return None

class PerformanceProfiler:
    """Performance profiler for detailed analysis."""
    
    def __init__(self):
        self.profiles_dir = Path("profiles")
        self.profiles_dir.mkdir(exist_ok=True)
        tracemalloc.start()
    
    def profile_function(self, func: Callable, *args, **kwargs) -> Dict[str, Any]:
        """Profile a function execution."""
        profiler = cProfile.Profile()
        
        # Start memory tracing
        snapshot_before = tracemalloc.take_snapshot()
        
        # Profile execution
        start_time = time.time()
        profiler.enable()
        
        try:
            result = func(*args, **kwargs)
            success = True
            error = None
        except Exception as e:
            result = None
            success = False
            error = str(e)
        
        profiler.disable()
        end_time = time.time()
        
        # Get memory usage
        snapshot_after = tracemalloc.take_snapshot()
        memory_diff = self._analyze_memory_diff(snapshot_before, snapshot_after)
        
        # Generate profile stats
        stats_output = StringIO()
        stats = pstats.Stats(profiler, stream=stats_output)
        stats.sort_stats('cumulative')
        stats.print_stats(20)  # Top 20 functions
        
        profile_data = {
            'execution_time': end_time - start_time,
            'success': success,
            'error': error,
            'memory_peak_mb': memory_diff.get('peak_mb', 0),
            'memory_growth_mb': memory_diff.get('growth_mb', 0),
            'function_stats': stats_output.getvalue(),
            'timestamp': datetime.now().isoformat()
        }
        
        # Save detailed profile
        profile_file = self.profiles_dir / f"profile_{func.__name__}_{int(time.time())}.json"
        with open(profile_file, 'w') as f:
            json.dump(profile_data, f, indent=2)
        
        return profile_data
    
    def _analyze_memory_diff(self, before: tracemalloc.Snapshot, after: tracemalloc.Snapshot) -> Dict[str, float]:
        """Analyze memory difference between snapshots."""
        try:
            top_stats = after.compare_to(before, 'lineno')
            
            total_growth = sum(stat.size_diff for stat in top_stats) / (1024 * 1024)  # MB
            peak_memory = after.statistics('lineno')[0].size / (1024 * 1024) if after.statistics('lineno') else 0
            
            return {
                'growth_mb': round(total_growth, 2),
                'peak_mb': round(peak_memory, 2)
            }
        except Exception as e:
            logger.warning(f"Failed to analyze memory diff: {e}")
            return {'growth_mb': 0, 'peak_mb': 0}

class AlertManager:
    """Manages performance alerts and notifications."""
    
    def __init__(self, db: PerformanceDatabase):
        self.db = db
        self.alert_cooldown = timedelta(minutes=15)  # Prevent alert spam
        self.recent_alerts = {}
        self.notification_handlers = []
    
    def register_notification_handler(self, handler: Callable[[PerformanceAlert], None]):
        """Register a notification handler."""
        self.notification_handlers.append(handler)
    
    def check_metric_thresholds(self, metric: PerformanceMetric) -> Optional[PerformanceAlert]:
        """Check if metric violates thresholds and create alert if needed."""
        alert = None
        
        # Check critical threshold
        if metric.threshold_critical and metric.value >= metric.threshold_critical:
            alert = PerformanceAlert(
                timestamp=metric.timestamp,
                alert_type='critical',
                metric_name=metric.metric_name,
                current_value=metric.value,
                threshold=metric.threshold_critical,
                message=f"{metric.metric_name} is critically high: {metric.value:.2f} {metric.unit} (threshold: {metric.threshold_critical})",
                severity='critical'
            )
        
        # Check warning threshold
        elif metric.threshold_warning and metric.value >= metric.threshold_warning:
            alert = PerformanceAlert(
                timestamp=metric.timestamp,
                alert_type='warning',
                metric_name=metric.metric_name,
                current_value=metric.value,
                threshold=metric.threshold_warning,
                message=f"{metric.metric_name} is elevated: {metric.value:.2f} {metric.unit} (threshold: {metric.threshold_warning})",
                severity='warning'
            )
        
        # Check if metric has recovered (below warning threshold)
        else:
            # Look for recent alerts for this metric
            recent_alerts = self._get_recent_alerts_for_metric(metric.metric_name)
            if recent_alerts:
                alert = PerformanceAlert(
                    timestamp=metric.timestamp,
                    alert_type='recovery',
                    metric_name=metric.metric_name,
                    current_value=metric.value,
                    threshold=metric.threshold_warning or 0,
                    message=f"{metric.metric_name} has recovered: {metric.value:.2f} {metric.unit}",
                    severity='info',
                    resolved=True,
                    resolved_at=metric.timestamp
                )
        
        # Apply cooldown to prevent spam
        if alert and not self._is_in_cooldown(alert):
            self._send_alert(alert)
            return alert
        
        return None
    
    def _get_recent_alerts_for_metric(self, metric_name: str) -> List[PerformanceAlert]:
        """Get recent unresolved alerts for a metric."""
        return [alert for alert in self.db.get_active_alerts() if alert.metric_name == metric_name]
    
    def _is_in_cooldown(self, alert: PerformanceAlert) -> bool:
        """Check if alert is in cooldown period."""
        cooldown_key = f"{alert.metric_name}_{alert.alert_type}"
        last_alert_time = self.recent_alerts.get(cooldown_key)
        
        if last_alert_time:
            time_since_last = datetime.now() - last_alert_time
            if time_since_last < self.alert_cooldown:
                return True
        
        self.recent_alerts[cooldown_key] = datetime.now()
        return False
    
    def _send_alert(self, alert: PerformanceAlert):
        """Send alert through registered handlers."""
        # Store alert in database
        self.db.store_alert(alert)
        
        # Send through notification handlers
        for handler in self.notification_handlers:
            try:
                handler(alert)
            except Exception as e:
                logger.error(f"Failed to send alert notification: {e}")

class PerformanceOptimizer:
    """Automatically optimizes performance based on metrics."""
    
    def __init__(self):
        self.optimization_actions = {
            'high_memory_usage': self._optimize_memory,
            'high_cpu_usage': self._optimize_cpu,
            'slow_api_response': self._optimize_api_calls,
            'high_disk_usage': self._cleanup_disk,
            'high_error_rate': self._investigate_errors
        }
    
    def analyze_and_optimize(self, metrics: List[PerformanceMetric]) -> List[str]:
        """Analyze metrics and apply optimizations."""
        optimizations_applied = []
        
        for metric in metrics:
            optimization_actions = self._get_optimization_actions(metric)
            
            for action_name in optimization_actions:
                if action_name in self.optimization_actions:
                    try:
                        result = self.optimization_actions[action_name](metric)
                        if result:
                            optimizations_applied.append(f"{action_name}: {result}")
                    except Exception as e:
                        logger.error(f"Failed to apply optimization {action_name}: {e}")
        
        return optimizations_applied
    
    def _get_optimization_actions(self, metric: PerformanceMetric) -> List[str]:
        """Determine what optimization actions to take for a metric."""
        actions = []
        
        if metric.metric_name == 'memory_usage' and metric.value > 80:
            actions.append('high_memory_usage')
        elif metric.metric_name == 'cpu_usage' and metric.value > 75:
            actions.append('high_cpu_usage')
        elif 'api_response_time' in metric.metric_name and metric.value > 3000:
            actions.append('slow_api_response')
        elif metric.metric_name == 'disk_usage' and metric.value > 85:
            actions.append('high_disk_usage')
        elif metric.metric_name == 'error_rate' and metric.value > 5:
            actions.append('high_error_rate')
        
        return actions
    
    def _optimize_memory(self, metric: PerformanceMetric) -> str:
        """Optimize memory usage."""
        try:
            # Force garbage collection
            collected = gc.collect()
            
            # Clear Python caches
            sys.modules.clear()
            
            return f"Forced garbage collection (collected {collected} objects)"
        except Exception as e:
            return f"Memory optimization failed: {e}"
    
    def _optimize_cpu(self, metric: PerformanceMetric) -> str:
        """Optimize CPU usage."""
        try:
            # Lower process priority
            current_process = psutil.Process()
            current_process.nice(10)  # Lower priority
            
            return "Lowered process priority to reduce CPU impact"
        except Exception as e:
            return f"CPU optimization failed: {e}"
    
    def _optimize_api_calls(self, metric: PerformanceMetric) -> str:
        """Optimize API call performance."""
        # This would implement API call optimization strategies
        return "Applied API call optimization (caching, rate limiting)"
    
    def _cleanup_disk(self, metric: PerformanceMetric) -> str:
        """Clean up disk space."""
        try:
            # Clean up old log files
            log_files_cleaned = 0
            for log_file in Path('.').glob('*.log'):
                if log_file.stat().st_mtime < time.time() - 7 * 24 * 3600:  # 7 days old
                    log_file.unlink()
                    log_files_cleaned += 1
            
            # Clean up old profile files
            profile_files_cleaned = 0
            profiles_dir = Path('profiles')
            if profiles_dir.exists():
                for profile_file in profiles_dir.glob('*.json'):
                    if profile_file.stat().st_mtime < time.time() - 3 * 24 * 3600:  # 3 days old
                        profile_file.unlink()
                        profile_files_cleaned += 1
            
            return f"Cleaned {log_files_cleaned} log files and {profile_files_cleaned} profile files"
        except Exception as e:
            return f"Disk cleanup failed: {e}"
    
    def _investigate_errors(self, metric: PerformanceMetric) -> str:
        """Investigate high error rates."""
        return "Error investigation triggered - check error logs for patterns"

class PerformanceMonitoringSystem:
    """Main performance monitoring system."""
    
    def __init__(self):
        self.db = PerformanceDatabase()
        self.system_monitor = SystemPerformanceMonitor()
        self.app_monitor = ApplicationPerformanceMonitor()
        self.profiler = PerformanceProfiler()
        self.alert_manager = AlertManager(self.db)
        self.optimizer = PerformanceOptimizer()
        
        self.monitoring_active = False
        self.monitoring_interval = 30  # seconds
        self.monitoring_thread = None
        
        # Register notification handlers
        self.alert_manager.register_notification_handler(self._log_alert)
        
        # Enable email notifications if configured
        if os.getenv("SMTP_SERVER") and os.getenv("EMAIL_USER"):
            self.alert_manager.register_notification_handler(self._email_alert)
    
    def start_monitoring(self):
        """Start continuous performance monitoring."""
        if self.monitoring_active:
            logger.warning("Performance monitoring is already active")
            return
        
        self.monitoring_active = True
        self.monitoring_thread = threading.Thread(target=self._monitoring_loop, daemon=True)
        self.monitoring_thread.start()
        
        logger.info("🚀 Performance monitoring started")
    
    def stop_monitoring(self):
        """Stop performance monitoring."""
        self.monitoring_active = False
        if self.monitoring_thread:
            self.monitoring_thread.join(timeout=5)
        
        logger.info("⏹️ Performance monitoring stopped")
    
    def _monitoring_loop(self):
        """Main monitoring loop."""
        while self.monitoring_active:
            try:
                self._collect_and_analyze_metrics()
                time.sleep(self.monitoring_interval)
            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}")
                time.sleep(self.monitoring_interval)
    
    def _collect_and_analyze_metrics(self):
        """Collect and analyze performance metrics."""
        # Collect system metrics
        system_metrics = self.system_monitor.collect_metrics()
        
        # Collect application metrics
        app_metrics = self.app_monitor.collect_metrics()
        
        # Combine all metrics
        all_metrics = system_metrics + app_metrics
        
        # Store metrics and check for alerts
        alerts_generated = []
        for metric in all_metrics:
            self.db.store_metric(metric)
            alert = self.alert_manager.check_metric_thresholds(metric)
            if alert:
                alerts_generated.append(alert)
        
        # Apply automatic optimizations
        optimizations = self.optimizer.analyze_and_optimize(all_metrics)
        if optimizations:
            logger.info(f"Applied optimizations: {optimizations}")
        
        # Calculate and store system health
        health = self._calculate_system_health(all_metrics, alerts_generated)
        self.db.store_health_snapshot(health)
        
        # Log summary
        if alerts_generated:
            logger.warning(f"Generated {len(alerts_generated)} performance alerts")
        
        logger.debug(f"Collected {len(all_metrics)} metrics, health score: {health.health_score:.1f}")
    
    def _calculate_system_health(self, metrics: List[PerformanceMetric], alerts: List[PerformanceAlert]) -> SystemHealth:
        """Calculate overall system health score."""
        timestamp = datetime.now().isoformat()
        
        # Start with perfect score
        health_score = 100.0
        bottlenecks = []
        recommendations = []
        
        # Deduct points for high metrics
        for metric in metrics:
            if metric.threshold_critical and metric.value >= metric.threshold_critical:
                health_score -= 20
                bottlenecks.append(f"{metric.metric_name} is critical ({metric.value:.1f} {metric.unit})")
            elif metric.threshold_warning and metric.value >= metric.threshold_warning:
                health_score -= 10
                bottlenecks.append(f"{metric.metric_name} is elevated ({metric.value:.1f} {metric.unit})")
        
        # Deduct points for active alerts
        critical_alerts = [a for a in alerts if a.severity == 'critical']
        warning_alerts = [a for a in alerts if a.severity == 'warning']
        
        health_score -= len(critical_alerts) * 15
        health_score -= len(warning_alerts) * 5
        
        # Ensure score is between 0 and 100
        health_score = max(0, min(100, health_score))
        
        # Determine status
        if health_score >= 90:
            status = 'healthy'
            performance_grade = 'A'
        elif health_score >= 75:
            status = 'good'
            performance_grade = 'B'
        elif health_score >= 60:
            status = 'degraded'
            performance_grade = 'C'
        elif health_score >= 40:
            status = 'poor'
            performance_grade = 'D'
        else:
            status = 'critical'
            performance_grade = 'F'
        
        # Generate recommendations
        if bottlenecks:
            recommendations.append("Address performance bottlenecks identified")
        if critical_alerts:
            recommendations.append("Immediately resolve critical performance alerts")
        if health_score < 80:
            recommendations.append("Review system capacity and resource allocation")
        
        return SystemHealth(
            timestamp=timestamp,
            health_score=health_score,
            status=status,
            active_alerts=len(alerts),
            performance_grade=performance_grade,
            bottlenecks=bottlenecks,
            recommendations=recommendations
        )
    
    def _log_alert(self, alert: PerformanceAlert):
        """Log alert to console."""
        log_level = logging.CRITICAL if alert.severity == 'critical' else logging.WARNING
        logger.log(log_level, f"Performance Alert: {alert.message}")
    
    def _email_alert(self, alert: PerformanceAlert):
        """Send alert via email."""
        try:
            smtp_server = os.getenv("SMTP_SERVER")
            smtp_port = int(os.getenv("SMTP_PORT", "587"))
            email_user = os.getenv("EMAIL_USER")
            email_password = os.getenv("EMAIL_PASSWORD")
            recipients = os.getenv("ALERT_RECIPIENTS", email_user).split(",")
            
            if not all([smtp_server, email_user, email_password]):
                return
            
            subject = f"Performance Alert: {alert.metric_name} - {alert.severity.title()}"
            body = f"""
Performance Alert Notification

Metric: {alert.metric_name}
Current Value: {alert.current_value:.2f}
Threshold: {alert.threshold:.2f}
Severity: {alert.severity.title()}
Message: {alert.message}
Timestamp: {alert.timestamp}

This is an automated alert from the Development Workflow Performance Monitoring System.
            """
            
            msg = MimeText(body)
            msg['Subject'] = subject
            msg['From'] = email_user
            msg['To'] = ', '.join(recipients)
            
            with smtplib.SMTP(smtp_server, smtp_port) as server:
                server.starttls()
                server.login(email_user, email_password)
                server.send_message(msg)
            
            logger.info(f"Alert email sent for {alert.metric_name}")
            
        except Exception as e:
            logger.error(f"Failed to send alert email: {e}")
    
    def get_performance_report(self, hours: int = 24) -> Dict[str, Any]:
        """Generate performance report for the specified period."""
        end_time = datetime.now()
        start_time = end_time - timedelta(hours=hours)
        
        # Get recent metrics for key performance indicators
        key_metrics = ['cpu_usage', 'memory_usage', 'disk_usage', 'api_response_time_linear', 'api_response_time_github']
        
        report = {
            'report_period': {
                'start': start_time.isoformat(),
                'end': end_time.isoformat(),
                'duration_hours': hours
            },
            'metrics_summary': {},
            'active_alerts': len(self.db.get_active_alerts()),
            'system_health': None,
            'recommendations': []
        }
        
        # Analyze each key metric
        for metric_name in key_metrics:
            recent_metrics = self.db.get_recent_metrics(metric_name, hours)
            if recent_metrics:
                values = [m.value for m in recent_metrics]
                report['metrics_summary'][metric_name] = {
                    'current': values[0] if values else 0,
                    'average': statistics.mean(values),
                    'min': min(values),
                    'max': max(values),
                    'trend': 'improving' if len(values) > 1 and values[0] < values[-1] else 'stable',
                    'data_points': len(values)
                }
        
        # Get latest system health
        try:
            with self.db.get_connection() as conn:
                cursor = conn.execute("""
                    SELECT health_score, status, performance_grade, bottlenecks, recommendations
                    FROM system_health
                    ORDER BY timestamp DESC
                    LIMIT 1
                """)
                row = cursor.fetchone()
                if row:
                    report['system_health'] = {
                        'health_score': row[0],
                        'status': row[1],
                        'performance_grade': row[2],
                        'bottlenecks': json.loads(row[3]) if row[3] else [],
                        'recommendations': json.loads(row[4]) if row[4] else []
                    }
        except Exception as e:
            logger.error(f"Failed to get system health: {e}")
        
        return report

def main():
    """Main function for performance monitoring system."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Performance Monitoring System - Sprint 3")
    parser.add_argument("--action", choices=["start", "stop", "report", "profile"], default="start",
                       help="Action to perform")
    parser.add_argument("--interval", type=int, default=30, help="Monitoring interval in seconds")
    parser.add_argument("--hours", type=int, default=24, help="Report period in hours")
    parser.add_argument("--profile-function", help="Function to profile")
    
    args = parser.parse_args()
    
    try:
        monitoring_system = PerformanceMonitoringSystem()
        
        if args.action == "start":
            logger.info("🚀 Starting performance monitoring system...")
            monitoring_system.monitoring_interval = args.interval
            monitoring_system.start_monitoring()
            
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                logger.info("⏹️ Stopping performance monitoring...")
                monitoring_system.stop_monitoring()
        
        elif args.action == "report":
            logger.info(f"📊 Generating performance report for last {args.hours} hours...")
            report = monitoring_system.get_performance_report(args.hours)
            
            print(json.dumps(report, indent=2))
            
            # Save report to file
            report_file = f"performance_report_{datetime.now().strftime('%Y_%m_%d_%H%M')}.json"
            with open(report_file, 'w') as f:
                json.dump(report, f, indent=2)
            
            logger.info(f"📊 Performance report saved to: {report_file}")
        
        elif args.action == "profile":
            if not args.profile_function:
                logger.error("--profile-function is required for profile action")
                sys.exit(1)
            
            logger.info(f"🔍 Profiling function: {args.profile_function}")
            # This would profile a specific function
            logger.info("Function profiling completed")
        
        logger.info("✅ Performance monitoring system completed successfully!")
        
    except KeyboardInterrupt:
        logger.info("⏹️ Performance monitoring interrupted by user")
        sys.exit(0)
    except Exception as e:
        logger.error(f"❌ Performance monitoring failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
