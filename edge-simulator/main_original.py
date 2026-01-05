"""
F1 Telemetry Edge Simulator
Simulates trackside telemetry collection and transmission to cloud
"""
import os
import time
import json
import random
import logging
from datetime import datetime
from typing import Dict, Any, Optional
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class F1DataCollector:
    """Collects F1 race data from Ergast API"""

    BASE_URL = "http://ergast.com/api/f1"

    def __init__(self):
        self.session = self._create_session()

    def _create_session(self) -> requests.Session:
        """Create requests session with retry logic"""
        session = requests.Session()
        retry = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504]
        )
        adapter = HTTPAdapter(max_retries=retry)
        session.mount("http://", adapter)
        session.mount("https://", adapter)
        return session

    def get_current_season_races(self) -> Optional[Dict[str, Any]]:
        """Fetch current season races"""
        try:
            url = f"{self.BASE_URL}/current.json"
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Error fetching races: {e}")
            return None

    def get_race_results(self, season: str = "current", round_num: str = "last") -> Optional[Dict[str, Any]]:
        """Fetch race results"""
        try:
            url = f"{self.BASE_URL}/{season}/{round_num}/results.json"
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Error fetching race results: {e}")
            return None

    def get_lap_times(self, season: str = "current", round_num: str = "last") -> Optional[Dict[str, Any]]:
        """Fetch lap times"""
        try:
            url = f"{self.BASE_URL}/{season}/{round_num}/laps.json"
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Error fetching lap times: {e}")
            return None

    def get_pit_stops(self, season: str = "current", round_num: str = "last") -> Optional[Dict[str, Any]]:
        """Fetch pit stop data"""
        try:
            url = f"{self.BASE_URL}/{season}/{round_num}/pitstops.json"
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Error fetching pit stops: {e}")
            return None

    def get_qualifying_results(self, season: str = "current", round_num: str = "last") -> Optional[Dict[str, Any]]:
        """Fetch qualifying results"""
        try:
            url = f"{self.BASE_URL}/{season}/{round_num}/qualifying.json"
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Error fetching qualifying: {e}")
            return None


class EdgeSimulator:
    """Simulates edge device behavior with network conditions"""

    def __init__(
        self,
        cloud_endpoint: str,
        simulate_latency: bool = True,
        simulate_packet_loss: bool = False,
        packet_loss_rate: float = 0.05
    ):
        self.cloud_endpoint = cloud_endpoint
        self.simulate_latency = simulate_latency
        self.simulate_packet_loss = simulate_packet_loss
        self.packet_loss_rate = packet_loss_rate
        self.collector = F1DataCollector()
        self.session = self._create_session()

        logger.info(f"Edge Simulator initialized")
        logger.info(f"Cloud endpoint: {cloud_endpoint}")
        logger.info(f"Latency simulation: {simulate_latency}")
        logger.info(f"Packet loss simulation: {simulate_packet_loss} (rate: {packet_loss_rate})")

    def _create_session(self) -> requests.Session:
        """Create requests session with retry logic"""
        session = requests.Session()
        retry = Retry(
            total=5,
            backoff_factor=2,
            status_forcelist=[429, 500, 502, 503, 504]
        )
        adapter = HTTPAdapter(max_retries=retry)
        session.mount("http://", adapter)
        session.mount("https://", adapter)
        return session

    def _simulate_network_conditions(self):
        """Simulate network latency and packet loss"""
        if self.simulate_latency:
            # Simulate variable network latency (50-500ms)
            latency = random.uniform(0.05, 0.5)
            time.sleep(latency)

        if self.simulate_packet_loss:
            # Randomly drop packets
            if random.random() < self.packet_loss_rate:
                raise Exception("Simulated packet loss")

    def _enrich_telemetry(self, data: Dict[str, Any], data_type: str) -> Dict[str, Any]:
        """Add edge metadata to telemetry"""
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "edge_id": os.environ.get("EDGE_ID", "edge-simulator-001"),
            "data_type": data_type,
            "payload": data,
            "metadata": {
                "collection_time": datetime.utcnow().isoformat(),
                "source": "ergast-api",
                "version": "1.0.0"
            }
        }

    def send_to_cloud(self, telemetry: Dict[str, Any]) -> bool:
        """Send telemetry to cloud endpoint"""
        try:
            self._simulate_network_conditions()

            response = self.session.post(
                self.cloud_endpoint,
                json=telemetry,
                timeout=30,
                headers={
                    "Content-Type": "application/json",
                    "X-Edge-ID": os.environ.get("EDGE_ID", "edge-simulator-001")
                }
            )
            response.raise_for_status()

            logger.info(f"Successfully sent {telemetry['data_type']} telemetry to cloud")
            return True

        except Exception as e:
            logger.error(f"Failed to send telemetry: {e}")
            return False

    def collect_and_send_race_results(self):
        """Collect and send race results"""
        logger.info("Collecting race results...")
        data = self.collector.get_race_results()
        if data:
            telemetry = self._enrich_telemetry(data, "race_results")
            return self.send_to_cloud(telemetry)
        return False

    def collect_and_send_lap_times(self):
        """Collect and send lap times"""
        logger.info("Collecting lap times...")
        data = self.collector.get_lap_times()
        if data:
            telemetry = self._enrich_telemetry(data, "lap_times")
            return self.send_to_cloud(telemetry)
        return False

    def collect_and_send_pit_stops(self):
        """Collect and send pit stop data"""
        logger.info("Collecting pit stops...")
        data = self.collector.get_pit_stops()
        if data:
            telemetry = self._enrich_telemetry(data, "pit_stops")
            return self.send_to_cloud(telemetry)
        return False

    def collect_and_send_qualifying(self):
        """Collect and send qualifying results"""
        logger.info("Collecting qualifying results...")
        data = self.collector.get_qualifying_results()
        if data:
            telemetry = self._enrich_telemetry(data, "qualifying")
            return self.send_to_cloud(telemetry)
        return False

    def run(self, interval: int = 60):
        """Main loop - collect and send data periodically"""
        logger.info(f"Starting edge simulator with {interval}s interval")

        while True:
            try:
                # Collect different types of data in rotation
                self.collect_and_send_race_results()
                time.sleep(5)

                self.collect_and_send_lap_times()
                time.sleep(5)

                self.collect_and_send_pit_stops()
                time.sleep(5)

                self.collect_and_send_qualifying()

                logger.info(f"Waiting {interval}s before next collection cycle...")
                time.sleep(interval)

            except KeyboardInterrupt:
                logger.info("Shutting down edge simulator...")
                break
            except Exception as e:
                logger.error(f"Error in main loop: {e}")
                time.sleep(10)


if __name__ == "__main__":
    # Configuration from environment variables
    cloud_endpoint = os.environ.get(
        "CLOUD_ENDPOINT",
        "http://localhost:8000/api/v1/telemetry"
    )

    interval = int(os.environ.get("COLLECTION_INTERVAL", "60"))
    simulate_latency = os.environ.get("SIMULATE_LATENCY", "true").lower() == "true"
    simulate_packet_loss = os.environ.get("SIMULATE_PACKET_LOSS", "false").lower() == "true"
    packet_loss_rate = float(os.environ.get("PACKET_LOSS_RATE", "0.05"))

    # Initialize and run simulator
    simulator = EdgeSimulator(
        cloud_endpoint=cloud_endpoint,
        simulate_latency=simulate_latency,
        simulate_packet_loss=simulate_packet_loss,
        packet_loss_rate=packet_loss_rate
    )

    simulator.run(interval=interval)
