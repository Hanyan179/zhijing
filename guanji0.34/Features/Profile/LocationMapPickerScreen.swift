import SwiftUI
import MapKit
import CoreLocation
import Combine
#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
typealias PlatformImage = UIImage
#else
import AppKit
typealias PlatformColor = NSColor
typealias PlatformImage = NSImage
#endif

public struct LocationMapPickerScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    public let mappingId: String
    private let initialRegionOverride: MKCoordinateRegion?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var region: MKCoordinateRegion
    @State private var query: String = ""
    @State private var searchResults: [MKMapItem] = []
    @StateObject private var locationManager = LocationManager()
    @State private var showLocationDeniedAlert: Bool = false
    @State private var appliedInitialLocation: Bool = false

    public init(vm: ProfileViewModel, mappingId: String, initialRegion: MKCoordinateRegion? = nil) {
        self.vm = vm
        self.mappingId = mappingId
        self.initialRegionOverride = initialRegion
        let fences = vm.addressFences.filter { $0.mappingId == mappingId }
        if let override = initialRegion {
            _region = State(initialValue: override)
        } else if fences.isEmpty {
            _region = State(initialValue: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)))
        } else {
            var minLat = fences.first!.lat
            var maxLat = fences.first!.lat
            var minLng = fences.first!.lng
            var maxLng = fences.first!.lng
            for f in fences {
                minLat = min(minLat, f.lat)
                maxLat = max(maxLat, f.lat)
                minLng = min(minLng, f.lng)
                maxLng = max(maxLng, f.lng)
            }
            let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2.0, longitude: (minLng + maxLng) / 2.0)
            let latDelta = max(0.02, (maxLat - minLat) * 1.5)
            let lngDelta = max(0.02, (maxLng - minLng) * 1.5)
            _region = State(initialValue: MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)))
        }
    }

    private func colorFor(_ name: String) -> Color {
        switch name {
        case "indigo": return Colors.indigo
        case "violet": return Colors.violet
        case "rose": return Colors.rose
        case "pink": return Colors.pink
        case "emerald": return Colors.emerald
        case "teal": return Colors.teal
        case "sky": return Colors.sky
        case "blue": return Colors.blue
        case "amber": return Colors.amber
        case "orange": return Colors.orange
        case "slate": return Colors.slatePrimary
        default: return Colors.systemGray
        }
    }

    private var mappingColor: Color {
        vm.addressMappings.first(where: { $0.id == mappingId })?.color.flatMap { colorFor($0) } ?? Colors.slateText
    }

    private func iconSystemName(_ id: String?) -> String {
        switch id ?? "mappin" {
        case "home": return "house"
        case "building": return "building.2"
        case "briefcase": return "briefcase"
        case "bag": return "bag"
        case "graduation": return "graduationcap"
        case "heart": return "heart.fill"
        case "tree": return "tree"
        case "airplane": return "airplane"
        case "bed": return "bed.double"
        case "food": return "fork.knife"
        default: return "mappin.circle"
        }
    }

    private var currentFences: [AddressFence] {
        vm.addressFences.filter { $0.mappingId == mappingId }
    }

    private var currentMapping: AddressMapping? {
        vm.addressMappings.first(where: { $0.id == mappingId })
    }

    public var body: some View {
        ZStack {
            MKMapViewRepresentable(region: $region,
                                   showsUserLocation: true,
                                   fenceAnnotations: allFenceAnnotations,
                                   fenceOverlays: allFenceOverlays)
                .ignoresSafeArea()

            VStack {
                Spacer()
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(mappingColor)
                    .shadow(color: Colors.slateText.opacity(0.15), radius: 4, x: 0, y: 2)
                Spacer()
            }

            VStack(spacing: 8) {
                Spacer()
                HStack(spacing: 8) {
                    Button(action: {
                        if let loc = locationManager.currentLocation {
                            region.center = loc.coordinate
                            region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        } else {
                            locationManager.request()
                        }
                    }) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 18))
                            .foregroundColor(mappingColor)
                    }
                    Text(String(format: Localization.tr("latLngFormat"), String(format: "%.4f", region.center.latitude), String(format: "%.4f", region.center.longitude)))
                        .font(.system(size: 12))
                        .foregroundColor(Colors.systemGray)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.bottom, 24)

            if !searchResults.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    List {
                        ForEach(Array(searchResults.enumerated()), id: \.offset) { pair in
                            let item = pair.element
                            Button(action: {
                                let c = item.placemark.coordinate
                                region.center = c
                                region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                searchResults.removeAll()
                            }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Colors.slateText)
                                    Text(item.placemark.title ?? "")
                                        .font(.system(size: 11))
                                        .foregroundColor(Colors.systemGray)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 12)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle(Localization.tr("selectOnMap"))
        .background(Colors.background.ignoresSafeArea())
        .id(appState.lang.rawValue)
        #if os(iOS)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: Localization.tr("searchPlace"))
        #else
        .searchable(text: $query)
        #endif
        .onSubmit(of: .search) {
            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = query
            req.region = region
            let search = MKLocalSearch(request: req)
            search.start { resp, _ in
                if let items = resp?.mapItems { self.searchResults = items }
            }
        }
        .onAppear {
            if initialRegionOverride == nil && currentFences.isEmpty {
                locationManager.request()
            }
        }
        .onReceive(locationManager.$status) { status in
            if status == .denied || status == .restricted {
                showLocationDeniedAlert = true
            }
        }
        .onReceive(locationManager.$currentLocation) { loc in
            if !appliedInitialLocation && initialRegionOverride == nil && currentFences.isEmpty, let loc = loc {
                region = MKCoordinateRegion(center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                appliedInitialLocation = true
            }
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) { Button(action: { dismiss() }) { Text(Localization.tr("cancel")) } }
            ToolbarItem(placement: .navigationBarTrailing) { Button(action: { vm.addFence(for: mappingId, name: Localization.tr("newAnchorName"), lat: region.center.latitude, lng: region.center.longitude); dismiss() }) { Text(Localization.tr("save")) } }
            #else
            ToolbarItem(placement: .automatic) { Button(action: { dismiss() }) { Text(Localization.tr("cancel")) } }
            ToolbarItem(placement: .automatic) { Button(action: { vm.addFence(for: mappingId, name: Localization.tr("newAnchorName"), lat: region.center.latitude, lng: region.center.longitude); dismiss() }) { Text(Localization.tr("save")) } }
            #endif
        }
        .alert(isPresented: $showLocationDeniedAlert) {
            Alert(title: Text(Localization.tr("location")), message: Text(Localization.tr("permLocationDenied")), dismissButton: .default(Text(Localization.tr("ok"))))
        }
    }
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation? = nil
    @Published var status: CLAuthorizationStatus = .notDetermined
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    func request() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            // keep status published; alert will be shown in view
        } else {
            manager.startUpdatingLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        manager.stopUpdatingLocation()
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        #if os(iOS)
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
        #else
        if status == .authorized {
            manager.startUpdatingLocation()
        }
        #endif
    }
}

struct FenceAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let uiColor: PlatformColor
    let icon: String
}

#if canImport(UIKit)
struct MKMapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var showsUserLocation: Bool
    var fenceAnnotations: [FenceAnnotation]
    var fenceOverlays: [MKColoredCircle]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.showsUserLocation = showsUserLocation
        map.setRegion(region, animated: false)
        return map
    }
    func updateUIView(_ map: MKMapView, context: Context) {
        if map.region.center.latitude != region.center.latitude || map.region.center.longitude != region.center.longitude {
            map.setRegion(region, animated: true)
        }
        map.removeAnnotations(map.annotations)
        let annos = fenceAnnotations.map { anno -> FencePointAnnotation in
            let a = FencePointAnnotation()
            a.coordinate = anno.coordinate
            a.title = anno.title
            a.icon = anno.icon
            a.uiColor = anno.uiColor
            return a
        }
        map.addAnnotations(annos)

        map.removeOverlays(map.overlays)
        map.addOverlays(fenceOverlays)
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private let parent: MKMapViewRepresentable
        init(_ parent: MKMapViewRepresentable) { self.parent = parent }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            let id = "fenceAnno"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            if let fp = annotation as? FencePointAnnotation {
                view.image = PlatformImage(systemName: fp.icon)
                view.tintColor = fp.uiColor
            } else {
                view.image = PlatformImage(systemName: "mappin.circle.fill")
            }
            view.canShowCallout = true
            return view
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKColoredCircle {
                let r = MKCircleRenderer(circle: circle)
                r.fillColor = circle.uiColor.withAlphaComponent(0.15)
                r.strokeColor = circle.uiColor.withAlphaComponent(0.5)
                r.lineWidth = 1
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
#else
struct MKMapViewRepresentable: NSViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var showsUserLocation: Bool
    var fenceAnnotations: [FenceAnnotation]
    var fenceOverlays: [MKColoredCircle]

    func makeNSView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.showsUserLocation = showsUserLocation
        map.setRegion(region, animated: false)
        return map
    }
    func updateNSView(_ map: MKMapView, context: Context) {
        if map.region.center.latitude != region.center.latitude || map.region.center.longitude != region.center.longitude {
            map.setRegion(region, animated: true)
        }
        map.removeAnnotations(map.annotations)
        let annos = fenceAnnotations.map { anno -> FencePointAnnotation in
            let a = FencePointAnnotation()
            a.coordinate = anno.coordinate
            a.title = anno.title
            a.icon = anno.icon
            a.uiColor = anno.uiColor
            return a
        }
        map.addAnnotations(annos)

        map.removeOverlays(map.overlays)
        map.addOverlays(fenceOverlays)
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private let parent: MKMapViewRepresentable
        init(_ parent: MKMapViewRepresentable) { self.parent = parent }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            let id = "fenceAnno"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            if let fp = annotation as? FencePointAnnotation {
                view.image = PlatformImage(systemSymbolName: fp.icon, accessibilityDescription: nil)
            } else {
                view.image = PlatformImage(systemSymbolName: "mappin.circle.fill", accessibilityDescription: nil)
            }
            view.canShowCallout = true
            return view
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKColoredCircle {
                let r = MKCircleRenderer(circle: circle)
                r.fillColor = circle.uiColor.withAlphaComponent(0.15)
                r.strokeColor = circle.uiColor.withAlphaComponent(0.5)
                r.lineWidth = 1
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
#endif

final class FencePointAnnotation: MKPointAnnotation {
    var icon: String = "mappin.circle.fill"
    var uiColor: PlatformColor = PlatformColor.systemBlue
}

final class MKColoredCircle: MKCircle {
    var uiColor: PlatformColor = PlatformColor.systemBlue
    static func circle(center: CLLocationCoordinate2D, radius: CLLocationDistance, color: PlatformColor) -> MKColoredCircle {
        let c = MKColoredCircle(center: center, radius: radius)
        c.uiColor = color
        return c
    }
}

private extension LocationMapPickerScreen {
    private func uiColorFor(_ name: String?) -> PlatformColor {
        let c = colorFor(name ?? "slate")
        #if canImport(UIKit)
        return UIColor(c)
        #else
        return NSColor(c)
        #endif
    }
    private var allFenceAnnotations: [FenceAnnotation] {
        vm.addressFences.map { f in
            let m = vm.addressMappings.first(where: { $0.id == f.mappingId })
            return FenceAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: f.lat, longitude: f.lng),
                title: f.originalRawName,
                uiColor: uiColorFor(m?.color),
                icon: iconSystemName(m?.icon)
            )
        }
    }
    private var allFenceOverlays: [MKColoredCircle] {
        vm.addressFences.map { f in
            let m = vm.addressMappings.first(where: { $0.id == f.mappingId })
            let color = uiColorFor(m?.color)
            return MKColoredCircle.circle(center: CLLocationCoordinate2D(latitude: f.lat, longitude: f.lng), radius: f.radius, color: color)
        }
    }
    private func regionThatFitsAllFences() -> MKCoordinateRegion {
        let fences = vm.addressFences
        guard !fences.isEmpty else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30))
        }
        var minLat = fences.first!.lat
        var maxLat = fences.first!.lat
        var minLng = fences.first!.lng
        var maxLng = fences.first!.lng
        for f in fences {
            minLat = min(minLat, f.lat)
            maxLat = max(maxLat, f.lat)
            minLng = min(minLng, f.lng)
            maxLng = max(maxLng, f.lng)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2.0, longitude: (minLng + maxLng) / 2.0)
        let latDelta = max(0.02, (maxLat - minLat) * 1.5)
        let lngDelta = max(0.02, (maxLng - minLng) * 1.5)
        return MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta))
    }
}
