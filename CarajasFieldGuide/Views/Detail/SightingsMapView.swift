import SwiftUI
import MapKit

// ─────────────────────────────────────────────────────────────────────────────
// SightingsMapView.swift
// Carajás Field Guide
//
// Embedded read-only map showing iNaturalist sightings for a single species.
// Inserted in SpeciesDetailView between iNatVisibilityView and ImageCreditView.
//
// Empty state (sightings.isEmpty) renders the section header + a "no records"
// label — no Map view is constructed.
// ─────────────────────────────────────────────────────────────────────────────

struct SightingsMapView: View {

    let sightings: [InatSighting]

    // Default centre used for the empty-state camera fallback — Serra dos Carajás.
    private static let carajasCentre = CLLocationCoordinate2D(
        latitude:  -6.05,
        longitude: -50.15
    )

    private func loc(_ key: String, _ fallback: String) -> String {
        LocaleManager.shared.localizedString(key, defaultValue: fallback)
    }

    // ── Camera position ───────────────────────────────────────────────────────

    /// Computes a MapCameraPosition that fits all sightings with ~20% padding.
    /// Single sighting → 50 km radius. Empty → not called.
    private var cameraPosition: MapCameraPosition {
        guard !sightings.isEmpty else {
            // Fallback — should not be reached; empty state skips the Map.
            return .region(MKCoordinateRegion(
                center: Self.carajasCentre,
                latitudinalMeters: 150_000,
                longitudinalMeters: 150_000
            ))
        }

        if sightings.count == 1 {
            return .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude:  sightings[0].lat,
                    longitude: sightings[0].lng
                ),
                latitudinalMeters: 50_000,
                longitudinalMeters: 50_000
            ))
        }

        let lats = sightings.map(\.lat)
        let lngs = sightings.map(\.lng)
        let minLat = lats.min()!,  maxLat = lats.max()!
        let minLng = lngs.min()!,  maxLng = lngs.max()!

        let centre = CLLocationCoordinate2D(
            latitude:  (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta:  max((maxLat - minLat) * 1.4, 0.05),
            longitudeDelta: max((maxLng - minLng) * 1.4, 0.05)
        )
        return .region(MKCoordinateRegion(center: centre, span: span))
    }

    // ── Body ──────────────────────────────────────────────────────────────────

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.labelMargin) {

            Text(loc("detail.sightings_title", "Sightings"))
                .sectionLabelStyle()

            if sightings.isEmpty {
                Text(loc("detail.sightings_none", "No observations recorded"))
                    .font(.bodyText)
                    .foregroundColor(.onSurfaceVariant)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Map(initialPosition: cameraPosition, interactionModes: []) {
                    ForEach(sightings.indices, id: \.self) { i in
                        Annotation(
                            "",
                            coordinate: CLLocationCoordinate2D(
                                latitude:  sightings[i].lat,
                                longitude: sightings[i].lng
                            )
                        ) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.appSecondary)
                        }
                    }
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.pill))

                // TODO: Replace with localised plural string via LocaleManager
                // once plural substitution support is added to the pipeline.
                // Pending key: detail.sightings_count ("%lld observations" / "%lld observações")
                Text("\(sightings.count) \(sightings.count == 1 ? "observation" : "observations")")
                    .font(.inatCount)
                    .foregroundColor(.appPrimary)
            }
        }
    }
}
