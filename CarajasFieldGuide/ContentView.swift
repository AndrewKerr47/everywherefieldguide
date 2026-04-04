import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// ContentView.swift
// Carajás Field Guide
//
// Root TabView with three tabs as defined in MasterDoc v0.3 Section 5.2:
//   - Home:    Active. NavigationStack root → species list.
//   - Guides:  Disabled (opacity 0.4). Future multi-taxon parent screen.
//   - Explore: Disabled (opacity 0.4). Future multi-region selector.
//
// HTML ref nav:
//   Home    → material icon: home     / SF fallback: house
//   Guides  → material icon: menu_book / SF fallback: books.vertical
//   Explore → material icon: explore  / SF fallback: safari
// ─────────────────────────────────────────────────────────────────────────────

enum Tab {
    case home, guides, explore
}

struct ContentView: View {

    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── Page content ─────────────────────────────────────────────────
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .guides:
                    // Disabled in MVP — never actually selected
                    Color.appBackground.ignoresSafeArea()
                case .explore:
                    // Disabled in MVP — never actually selected
                    Color.appBackground.ignoresSafeArea()
                }
            }

            // ── Bottom nav bar ────────────────────────────────────────────────
            // HTML ref:
            //   fixed bottom-0 w-full z-50
            //   flex justify-around items-center px-6 pb-8 pt-4
            //   bg-stone-50/70 backdrop-blur-xl
            //   shadow-[0_-8px_30px_rgb(0,0,0,0.04)]
            BottomNavBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Bottom nav bar
// ─────────────────────────────────────────────────────────────────────────────

struct BottomNavBar: View {

    @Binding var selectedTab: Tab

    var body: some View {
        VStack(spacing: 0) {
            // Hairline separator at top of nav bar
            Rectangle()
                .fill(Color.outlineVariant.opacity(0.3))
                .frame(height: 0.5)

            HStack(spacing: 0) {

                // ── Home — active ─────────────────────────────────────────────
                NavTabButton(
                    icon:     "house",
                    label:    "Home",
                    isActive: selectedTab == .home,
                    disabled: false
                ) {
                    selectedTab = .home
                }

                // ── Guides — disabled ─────────────────────────────────────────
                NavTabButton(
                    icon:     "books.vertical",
                    label:    "Guides",
                    isActive: false,
                    disabled: true
                ) {}

                // ── Explore — disabled ────────────────────────────────────────
                NavTabButton(
                    icon:     "safari",
                    label:    "Explore",
                    isActive: false,
                    disabled: true
                ) {}
            }
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.top, 16)
            .padding(.bottom, 32) // safe area clearance
        }
        .background(.ultraThinMaterial)
        // Mimics: shadow-[0_-8px_30px_rgb(0,0,0,0.04)]
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: -8)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Individual tab button
// ─────────────────────────────────────────────────────────────────────────────

struct NavTabButton: View {

    let icon:     String   // SF Symbols name
    let label:    String
    let isActive: Bool
    let disabled: Bool
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))

                Text(label)
                    .font(.navLabel)
                    .textCase(.uppercase)
                    .tracking(1.0)
            }
            // Active:   text-emerald-900 = appPrimary (#23422a)
            // Inactive: stone-300 greyed at opacity 0.4
            .foregroundColor(isActive ? .navActive : .navInactive)
            .opacity(disabled ? 0.4 : 1.0)
            .frame(maxWidth: .infinity)
        }
        .disabled(disabled)
        .buttonStyle(NavButtonStyle())
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Nav button press style
// ─────────────────────────────────────────────────────────────────────────────

struct NavButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────────────────────────────────────

#Preview {
    ContentView()
}

