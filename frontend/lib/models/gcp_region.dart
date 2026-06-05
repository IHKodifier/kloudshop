class GcpRegion {
  final String id;
  final String name;
  final String location;
  final String continent;
  final double latitude;
  final double longitude;
  final String customerTarget;

  const GcpRegion({
    required this.id,
    required this.name,
    required this.location,
    required this.continent,
    required this.latitude,
    required this.longitude,
    required this.customerTarget,
  });
}

const Map<String, GcpRegion> gcpRegions = {
  // Americas
  'us-central1': GcpRegion(id: 'us-central1', name: 'US Central', location: 'Iowa, USA', continent: 'Americas', latitude: 41.26, longitude: -95.86, customerTarget: 'North America'),
  'us-east1': GcpRegion(id: 'us-east1', name: 'US East', location: 'South Carolina, USA', continent: 'Americas', latitude: 33.19, longitude: -80.01, customerTarget: 'Eastern US & Canada'),
  'us-east4': GcpRegion(id: 'us-east4', name: 'US East', location: 'Northern Virginia, USA', continent: 'Americas', latitude: 39.04, longitude: -77.47, customerTarget: 'Eastern US & Canada'),
  'us-west1': GcpRegion(id: 'us-west1', name: 'US West', location: 'Oregon, USA', continent: 'Americas', latitude: 45.84, longitude: -119.70, customerTarget: 'Western US & Canada'),
  'us-west2': GcpRegion(id: 'us-west2', name: 'US West', location: 'Los Angeles, USA', continent: 'Americas', latitude: 34.05, longitude: -118.24, customerTarget: 'Western US'),
  'us-west3': GcpRegion(id: 'us-west3', name: 'US West', location: 'Salt Lake City, USA', continent: 'Americas', latitude: 40.76, longitude: -111.89, customerTarget: 'Western US'),
  'us-west4': GcpRegion(id: 'us-west4', name: 'US West', location: 'Las Vegas, USA', continent: 'Americas', latitude: 36.17, longitude: -115.14, customerTarget: 'Western US'),
  'northamerica-northeast1': GcpRegion(id: 'northamerica-northeast1', name: 'North America Northeast', location: 'Montreal, Canada', continent: 'Americas', latitude: 45.50, longitude: -73.56, customerTarget: 'Eastern Canada'),
  'northamerica-northeast2': GcpRegion(id: 'northamerica-northeast2', name: 'North America Northeast', location: 'Toronto, Canada', continent: 'Americas', latitude: 43.65, longitude: -79.38, customerTarget: 'Eastern Canada'),
  'southamerica-east1': GcpRegion(id: 'southamerica-east1', name: 'South America East', location: 'Sao Paulo, Brazil', continent: 'Americas', latitude: -23.55, longitude: -46.63, customerTarget: 'South America'),
  'southamerica-west1': GcpRegion(id: 'southamerica-west1', name: 'South America West', location: 'Santiago, Chile', continent: 'Americas', latitude: -33.45, longitude: -70.66, customerTarget: 'South America'),
  
  // Europe
  'europe-west1': GcpRegion(id: 'europe-west1', name: 'Europe West', location: 'Belgium', continent: 'Europe', latitude: 50.85, longitude: 4.35, customerTarget: 'Western Europe'),
  'europe-west2': GcpRegion(id: 'europe-west2', name: 'Europe West', location: 'London, UK', continent: 'Europe', latitude: 51.51, longitude: -0.13, customerTarget: 'UK & Ireland'),
  'europe-west3': GcpRegion(id: 'europe-west3', name: 'Europe West', location: 'Frankfurt, Germany', continent: 'Europe', latitude: 50.11, longitude: 8.68, customerTarget: 'Central & Western Europe'),
  'europe-west4': GcpRegion(id: 'europe-west4', name: 'Europe West', location: 'Eemshaven, Netherlands', continent: 'Europe', latitude: 53.43, longitude: 6.83, customerTarget: 'Western Europe'),
  'europe-west6': GcpRegion(id: 'europe-west6', name: 'Europe West', location: 'Zurich, Switzerland', continent: 'Europe', latitude: 47.37, longitude: 8.54, customerTarget: 'Central Europe'),
  'europe-west8': GcpRegion(id: 'europe-west8', name: 'Europe West', location: 'Milan, Italy', continent: 'Europe', latitude: 45.46, longitude: 9.19, customerTarget: 'Southern Europe'),
  'europe-west9': GcpRegion(id: 'europe-west9', name: 'Europe West', location: 'Paris, France', continent: 'Europe', latitude: 48.86, longitude: 2.35, customerTarget: 'Western Europe'),
  'europe-west10': GcpRegion(id: 'europe-west10', name: 'Europe West', location: 'Berlin, Germany', continent: 'Europe', latitude: 52.52, longitude: 13.40, customerTarget: 'Central & Eastern Europe'),
  'europe-west12': GcpRegion(id: 'europe-west12', name: 'Europe West', location: 'Turin, Italy', continent: 'Europe', latitude: 45.07, longitude: 7.68, customerTarget: 'Southern Europe'),
  'europe-north1': GcpRegion(id: 'europe-north1', name: 'Europe North', location: 'Finland', continent: 'Europe', latitude: 60.17, longitude: 24.94, customerTarget: 'Nordics & Baltics'),
  'europe-southwest1': GcpRegion(id: 'europe-southwest1', name: 'Europe Southwest', location: 'Madrid, Spain', continent: 'Europe', latitude: 40.42, longitude: -3.70, customerTarget: 'Iberian Peninsula'),
  
  // Asia Pacific
  'asia-east1': GcpRegion(id: 'asia-east1', name: 'Asia East', location: 'Taiwan', continent: 'Asia Pacific', latitude: 25.03, longitude: 121.56, customerTarget: 'East Asia'),
  'asia-east2': GcpRegion(id: 'asia-east2', name: 'Asia East', location: 'Hong Kong', continent: 'Asia Pacific', latitude: 22.32, longitude: 114.17, customerTarget: 'East & Southeast Asia'),
  'asia-northeast1': GcpRegion(id: 'asia-northeast1', name: 'Asia Northeast', location: 'Tokyo, Japan', continent: 'Asia Pacific', latitude: 35.68, longitude: 139.69, customerTarget: 'Japan & Northeast Asia'),
  'asia-northeast2': GcpRegion(id: 'asia-northeast2', name: 'Asia Northeast', location: 'Osaka, Japan', continent: 'Asia Pacific', latitude: 34.69, longitude: 135.50, customerTarget: 'Japan'),
  'asia-northeast3': GcpRegion(id: 'asia-northeast3', name: 'Asia Northeast', location: 'Seoul, South Korea', continent: 'Asia Pacific', latitude: 37.56, longitude: 126.97, customerTarget: 'Korea'),
  'asia-south1': GcpRegion(id: 'asia-south1', name: 'Asia South', location: 'Mumbai, India', continent: 'Asia Pacific', latitude: 19.08, longitude: 72.88, customerTarget: 'India & South Asia'),
  'asia-south2': GcpRegion(id: 'asia-south2', name: 'Asia South', location: 'Delhi, India', continent: 'Asia Pacific', latitude: 28.61, longitude: 77.21, customerTarget: 'India & South Asia'),
  'asia-southeast1': GcpRegion(id: 'asia-southeast1', name: 'Asia Southeast', location: 'Singapore', continent: 'Asia Pacific', latitude: 1.35, longitude: 103.82, customerTarget: 'Southeast Asia'),
  'asia-southeast2': GcpRegion(id: 'asia-southeast2', name: 'Asia Southeast', location: 'Jakarta, Indonesia', continent: 'Asia Pacific', latitude: -6.20, longitude: 106.82, customerTarget: 'Southeast Asia'),
  'australia-southeast1': GcpRegion(id: 'australia-southeast1', name: 'Australia Southeast', location: 'Sydney, Australia', continent: 'Asia Pacific', latitude: -33.87, longitude: 151.21, customerTarget: 'Australia & New Zealand'),
  'australia-southeast2': GcpRegion(id: 'australia-southeast2', name: 'Australia Southeast', location: 'Melbourne, Australia', continent: 'Asia Pacific', latitude: -37.81, longitude: 144.96, customerTarget: 'Australia'),
  
  // Middle East / Africa
  'me-central1': GcpRegion(id: 'me-central1', name: 'Middle East Central', location: 'Doha, Qatar', continent: 'Middle East / Africa', latitude: 25.29, longitude: 51.53, customerTarget: 'Middle East'),
  'me-central2': GcpRegion(id: 'me-central2', name: 'Middle East Central', location: 'Dammam, Saudi Arabia', continent: 'Middle East / Africa', latitude: 26.42, longitude: 50.09, customerTarget: 'Middle East'),
  'me-west1': GcpRegion(id: 'me-west1', name: 'Middle East West', location: 'Tel Aviv, Israel', continent: 'Middle East / Africa', latitude: 32.08, longitude: 34.78, customerTarget: 'Middle East'),
  'africa-south1': GcpRegion(id: 'africa-south1', name: 'Africa South', location: 'Johannesburg, South Africa', continent: 'Middle East / Africa', latitude: -26.20, longitude: 28.04, customerTarget: 'Southern Africa'),
};
