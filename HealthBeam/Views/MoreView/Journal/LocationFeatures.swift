import SwiftUI
import MapKit
import CoreLocation
import Combine
struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}
struct MultiLocationMapView: View {
    let locations: [MapAnnotationItem]
    @State var region: MKCoordinateRegion

    init(locations: [MapAnnotationItem]) {
        self.locations = locations
        self._region = State(initialValue: MKCoordinateRegion.defaultRegion)
        if !locations.isEmpty {
            self._region = State(initialValue: MultiLocationMapView.calculateRegion(for: locations))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Map(initialPosition: .region(region)) {
                ForEach(locations) { location in
                    Marker(location.name, coordinate: location.coordinate)
                        .tint(.pink)
                }
            }
            .frame(height: 200)
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.secondary)
                VStack(alignment: .leading) {
                    Text("\(locations.count) Location Added").font(.headline)
                    Text("All Locations").font(.subheadline).foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.secondarySystemGroupedBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    static func calculateRegion(for locations: [MapAnnotationItem]) -> MKCoordinateRegion {
        guard !locations.isEmpty else { return .defaultRegion }
        var minLat = locations.first!.coordinate.latitude
        var maxLat = locations.first!.coordinate.latitude
        var minLon = locations.first!.coordinate.longitude
        var maxLon = locations.first!.coordinate.longitude
        for location in locations {
            minLat = min(minLat, location.coordinate.latitude)
            maxLat = max(maxLat, location.coordinate.latitude)
            minLon = min(minLon, location.coordinate.longitude)
            maxLon = max(maxLon, location.coordinate.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.4, longitudeDelta: (maxLon - minLon) * 1.4)
        return MKCoordinateRegion(center: center, span: span)
    }
}
struct AddLocationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = AddLocationViewModel()
    @State var searchText: String = ""
    var onLocationSelected: (String, CLLocationCoordinate2D) -> Void
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search Location...", text: $searchText)
                }
                .padding(12)
                .background(Color.secondarySystemGroupedBackground)
                .cornerRadius(10)
                .padding()
                .onChange(of: searchText) { _, newValue in
                    viewModel.searchLocations(query: newValue)
                }
                List {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    if let error = viewModel.locationError {
                        Text(error.localizedDescription).foregroundColor(.red)
                    }
                    ForEach(viewModel.searchResults, id: \.self) { completion in
                        Button(action: {
                            viewModel.getCoordinate(from: completion) { mapItem in
                                if let mapItem = mapItem {
                                    let c = mapItem.location.coordinate
                                    onLocationSelected(mapItem.name ?? completion.title, c)
                                    dismiss()
                                }
                            }
                        }) {
                            VStack(alignment: .leading) {
                                Text(completion.title).font(.headline)
                                Text(completion.subtitle).font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: viewModel.requestLocation)
        }
    }
}
@MainActor
class AddLocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate, MKLocalSearchCompleterDelegate {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isLoading = false
    @Published var locationError: Error?
    private let locationManager = CLLocationManager()
    private var searchCompleter = MKLocalSearchCompleter()
    override init() {
        super.init()
        locationManager.delegate = self
        searchCompleter.delegate = self
    }
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
    }
    func searchLocations(query: String) {
        searchCompleter.queryFragment = query
    }
    func getCoordinate(from completion: MKLocalSearchCompletion, completionHandler: @escaping (MKMapItem?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            completionHandler(response?.mapItems.first)
        }
    }
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
    }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.locationError = error
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
}
