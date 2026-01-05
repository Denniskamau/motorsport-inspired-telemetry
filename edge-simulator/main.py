"""
F1 Telemetry Edge Simulator - Replay Mode
Replays cached 2024 race data as live telemetry
"""
import os
import time
import json
import random
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class CachedDataReplayer:
    """Replays cached F1 race data as live telemetry"""

    def __init__(self, cache_dir: str = "/app/cache-data"):
        self.cache_dir = cache_dir
        self.race_data = {}
        self._load_cached_data()

    def _load_cached_data(self):
        """Load cached race data from JSON files"""
        data_files = {
            'results': '2024-bahrain-results.json',
            'pitstops': '2024-bahrain-pitstops.json',
            'qualifying': '2024-bahrain-qualifying.json',
            'laps': '2024-bahrain-laps.json',
            'fastest_laps': '2024-bahrain-fastest-laps.json',
            'driver_standings': '2024-bahrain-driver-standings.json',
            'constructor_standings': '2024-bahrain-constructor-standings.json'
        }

        for data_type, filename in data_files.items():
            filepath = os.path.join(self.cache_dir, filename)
            try:
                with open(filepath, 'r') as f:
                    self.race_data[data_type] = json.load(f)
                logger.info(f"✓ Loaded cached {data_type} data from {filename}")
            except FileNotFoundError:
                logger.warning(f"✗ Cache file not found: {filename}")
                self.race_data[data_type] = None
            except Exception as e:
                logger.error(f"✗ Error loading {filename}: {e}")
                self.race_data[data_type] = None

    def get_race_results(self) -> Optional[Dict[str, Any]]:
        """Get race results with current timestamp"""
        if self.race_data.get('results'):
            data = self.race_data['results'].copy()
            # Add live timestamp
            if 'MRData' in data and 'RaceTable' in data['MRData']:
                if 'Races' in data['MRData']['RaceTable'] and data['MRData']['RaceTable']['Races']:
                    race = data['MRData']['RaceTable']['Races'][0]
                    logger.info(f"📊 Replaying: {race.get('raceName', 'Unknown')} {race.get('season', '')} - Race Results")
            return data
        return None

    def get_pit_stops(self) -> Optional[Dict[str, Any]]:
        """Get pit stop data with current timestamp"""
        if self.race_data.get('pitstops'):
            data = self.race_data['pitstops'].copy()
            if 'MRData' in data and 'RaceTable' in data['MRData']:
                if 'Races' in data['MRData']['RaceTable'] and data['MRData']['RaceTable']['Races']:
                    race = data['MRData']['RaceTable']['Races'][0]
                    logger.info(f"⛽ Replaying: {race.get('raceName', 'Unknown')} - Pit Stops")
            return data
        return None

    def get_qualifying_results(self) -> Optional[Dict[str, Any]]:
        """Get qualifying results with current timestamp"""
        if self.race_data.get('qualifying'):
            data = self.race_data['qualifying'].copy()
            if 'MRData' in data and 'RaceTable' in data['MRData']:
                if 'Races' in data['MRData']['RaceTable'] and data['MRData']['RaceTable']['Races']:
                    race = data['MRData']['RaceTable']['Races'][0]
                    logger.info(f"🏁 Replaying: {race.get('raceName', 'Unknown')} - Qualifying")
            return data
        return None

    def get_lap_times(self) -> Optional[Dict[str, Any]]:
        """Get lap timing data"""
        if self.race_data.get('laps'):
            data = self.race_data['laps'].copy()
            if 'MRData' in data and 'RaceTable' in data['MRData']:
                if 'Races' in data['MRData']['RaceTable'] and data['MRData']['RaceTable']['Races']:
                    race = data['MRData']['RaceTable']['Races'][0]
                    logger.info(f"⏱️  Replaying: {race.get('raceName', 'Unknown')} - Lap Times")
            return data
        return None

    def get_fastest_laps(self) -> Optional[Dict[str, Any]]:
        """Get fastest lap data"""
        if self.race_data.get('fastest_laps'):
            data = self.race_data['fastest_laps'].copy()
            if 'MRData' in data and 'RaceTable' in data['MRData']:
                if 'Races' in data['MRData']['RaceTable'] and data['MRData']['RaceTable']['Races']:
                    race = data['MRData']['RaceTable']['Races'][0]
                    logger.info(f"🏎️  Replaying: {race.get('raceName', 'Unknown')} - Fastest Laps")
            return data
        return None

    def get_driver_standings(self) -> Optional[Dict[str, Any]]:
        """Get driver championship standings"""
        if self.race_data.get('driver_standings'):
            data = self.race_data['driver_standings'].copy()
            if 'MRData' in data and 'StandingsTable' in data['MRData']:
                logger.info(f"👤 Replaying: Driver Standings")
            return data
        return None

    def get_constructor_standings(self) -> Optional[Dict[str, Any]]:
        """Get constructor championship standings"""
        if self.race_data.get('constructor_standings'):
            data = self.race_data['constructor_standings'].copy()
            if 'MRData' in data and 'StandingsTable' in data['MRData']:
                logger.info(f"🏁 Replaying: Constructor Standings")
            return data
        return None


class EdgeSimulator:
    """Simulates edge device behavior with network conditions"""

    def __init__(
        self,
        cloud_endpoint: str,
        simulate_latency: bool = True,
        simulate_packet_loss: bool = False,
        packet_loss_rate: float = 0.02
    ):
        self.cloud_endpoint = cloud_endpoint
        self.simulate_latency = simulate_latency
        self.simulate_packet_loss = simulate_packet_loss
        self.packet_loss_rate = packet_loss_rate
        self.replayer = CachedDataReplayer()
        self.session = self._create_session()

        logger.info(f"🏎️  Edge Simulator initialized - REPLAY MODE")
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
            # Simulate variable network latency (20-200ms for trackside)
            latency = random.uniform(0.02, 0.2)
            time.sleep(latency)

        if self.simulate_packet_loss:
            # Randomly drop packets
            if random.random() < self.packet_loss_rate:
                raise Exception("Simulated packet loss")

    def _enrich_telemetry(self, data: Dict[str, Any], data_type: str) -> Dict[str, Any]:
        """Add edge metadata to telemetry"""
        return {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "edge_id": os.environ.get("EDGE_ID", "trackside-edge-001"),
            "data_type": data_type,
            "payload": data,
            "metadata": {
                "collection_time": datetime.utcnow().isoformat() + "Z",
                "source": "cached-replay-2024-bahrain",
                "version": "1.0.0",
                "race": "2024 Bahrain Grand Prix",
                "replay_mode": True
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
                    "X-Edge-ID": os.environ.get("EDGE_ID", "trackside-edge-001"),
                    "X-Race-Mode": "replay"
                }
            )
            response.raise_for_status()

            logger.info(f"✅ Successfully sent {telemetry['data_type']} telemetry to cloud")
            return True

        except Exception as e:
            logger.error(f"❌ Failed to send telemetry: {e}")
            return False

    def collect_and_send_race_results(self):
        """Collect and send race results"""
        data = self.replayer.get_race_results()
        if data:
            telemetry = self._enrich_telemetry(data, "race_results")
            return self.send_to_cloud(telemetry)
        else:
            logger.warning("No race results data available")
        return False

    def collect_and_send_pit_stops(self):
        """Collect and send pit stop data"""
        data = self.replayer.get_pit_stops()
        if data:
            telemetry = self._enrich_telemetry(data, "pit_stops")
            return self.send_to_cloud(telemetry)
        else:
            logger.warning("No pit stop data available")
        return False

    def collect_and_send_qualifying(self):
        """Collect and send qualifying results"""
        data = self.replayer.get_qualifying_results()
        if data:
            telemetry = self._enrich_telemetry(data, "qualifying")
            return self.send_to_cloud(telemetry)
        else:
            logger.warning("No qualifying data available")
        return False

    def collect_and_send_lap_times(self):
        """Collect and send lap timing data"""
        data = self.replayer.get_lap_times()
        if data:
            telemetry = self._enrich_telemetry(data, "lap_times")
            return self.send_to_cloud(telemetry)
        else:
            logger.warning("No lap times data available")
        return False

    def collect_and_send_fastest_laps(self):
        """Collect and send fastest lap data"""
        data = self.replayer.get_fastest_laps()
        if data:
            telemetry = self._enrich_telemetry(data, "fastest_laps")
            return self.send_to_cloud(telemetry)
        else:
            logger.warning("No fastest laps data available")
        return False

    def collect_and_send_driver_standings(self):
        """Collect and send driver championship standings"""
        data = self.replayer.get_driver_standings()
        if data:
            telemetry = self._enrich_telemetry(data, "driver_standings")
            return self.send_to_cloud(telemetry)
        else:
            logger.warning("No driver standings data available")
        return False

    def collect_and_send_constructor_standings(self):
        """Collect and send constructor championship standings"""
        data = self.replayer.get_constructor_standings()
        if data:
            telemetry = self._enrich_telemetry(data, "constructor_standings")
            return self.send_to_cloud(telemetry)
        else:
            logger.warning("No constructor standings data available")
        return False

    def run(self, interval: int = 30):
        """Main loop - replay race data at intervals"""
        logger.info(f"🚀 Starting race replay with {interval}s interval")
        logger.info(f"📡 Simulating trackside edge device transmitting to cloud...")

        cycle_count = 0
        while True:
            try:
                cycle_count += 1
                logger.info(f"")
                logger.info(f"{'='*60}")
                logger.info(f"🔄 Replay Cycle #{cycle_count}")
                logger.info(f"{'='*60}")

                # Simulate race weekend data flow
                logger.info("📊 Transmitting race results...")
                self.collect_and_send_race_results()
                time.sleep(2)

                logger.info("⛽ Transmitting pit stop telemetry...")
                self.collect_and_send_pit_stops()
                time.sleep(2)

                logger.info("🏁 Transmitting qualifying data...")
                self.collect_and_send_qualifying()
                time.sleep(2)

                logger.info("⏱️  Transmitting lap times...")
                self.collect_and_send_lap_times()
                time.sleep(2)

                logger.info("🏎️  Transmitting fastest laps...")
                self.collect_and_send_fastest_laps()
                time.sleep(2)

                logger.info("👤 Transmitting driver standings...")
                self.collect_and_send_driver_standings()
                time.sleep(2)

                logger.info("🏁 Transmitting constructor standings...")
                self.collect_and_send_constructor_standings()

                logger.info(f"")
                logger.info(f"⏸️  Waiting {interval}s before next transmission...")
                time.sleep(interval)

            except KeyboardInterrupt:
                logger.info("🛑 Shutting down edge simulator...")
                break
            except Exception as e:
                logger.error(f"❌ Error in main loop: {e}")
                time.sleep(10)


if __name__ == "__main__":
    # Configuration from environment variables
    cloud_endpoint = os.environ.get(
        "CLOUD_ENDPOINT",
        "http://localhost:8000/api/v1/telemetry"
    )

    interval = int(os.environ.get("COLLECTION_INTERVAL", "30"))
    simulate_latency = os.environ.get("SIMULATE_LATENCY", "true").lower() == "true"
    simulate_packet_loss = os.environ.get("SIMULATE_PACKET_LOSS", "false").lower() == "true"
    packet_loss_rate = float(os.environ.get("PACKET_LOSS_RATE", "0.02"))

    # Initialize and run simulator
    simulator = EdgeSimulator(
        cloud_endpoint=cloud_endpoint,
        simulate_latency=simulate_latency,
        simulate_packet_loss=simulate_packet_loss,
        packet_loss_rate=packet_loss_rate
    )

    simulator.run(interval=interval)
