import SwiftUI

struct iPodLayoutView<Content: View>: View {
    let content: Content
    let onMenuPress: () -> Void
    let onPlayPausePress: () -> Void
    let onPreviousPress: () -> Void
    let onNextPress: () -> Void
    let onCenterPress: () -> Void
    let onScrollUp: () -> Void
    let onScrollDown: () -> Void
    let onScrollLeft: () -> Void
    let onScrollRight: () -> Void
    let onVolumeUp: () -> Void
    let onVolumeDown: () -> Void
    
    init(
        @ViewBuilder content: () -> Content,
        onMenuPress: @escaping () -> Void = {},
        onPlayPausePress: @escaping () -> Void = {},
        onPreviousPress: @escaping () -> Void = {},
        onNextPress: @escaping () -> Void = {},
        onCenterPress: @escaping () -> Void = {},
        onScrollUp: @escaping () -> Void = {},
        onScrollDown: @escaping () -> Void = {},
        onScrollLeft: @escaping () -> Void = {},
        onScrollRight: @escaping () -> Void = {},
        onVolumeUp: @escaping () -> Void = {},
        onVolumeDown: @escaping () -> Void = {}
    ) {
        self.content = content()
        self.onMenuPress = onMenuPress
        self.onPlayPausePress = onPlayPausePress
        self.onPreviousPress = onPreviousPress
        self.onNextPress = onNextPress
        self.onCenterPress = onCenterPress
        self.onScrollUp = onScrollUp
        self.onScrollDown = onScrollDown
        self.onScrollLeft = onScrollLeft
        self.onScrollRight = onScrollRight
        self.onVolumeUp = onVolumeUp
        self.onVolumeDown = onVolumeDown
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // iPod Screen - fixed size and position
            iPodScreen
            
            Spacer()
            
            // Click Wheel - consistent throughout app
            clickWheel
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
    }
    
    private var iPodScreen: some View {
        content
            .frame(width: 320, height: 240)
            .background(screenBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .clipped() // Ensure content doesn't overflow
    }
    
    private var screenBackground: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white,
                Color.gray.opacity(0.1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.3)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var clickWheel: some View {
        ClickWheelView(
            onMenuPress: onMenuPress,
            onPlayPausePress: onPlayPausePress,
            onPreviousPress: onPreviousPress,
            onNextPress: onNextPress,
            onCenterPress: onCenterPress,
            onScrollUp: onScrollUp,
            onScrollDown: onScrollDown,
            onScrollLeft: onScrollLeft,
            onScrollRight: onScrollRight,
            onVolumeUp: onVolumeUp,
            onVolumeDown: onVolumeDown
        )
    }
}

// Common screen header component
struct iPodScreenHeader: View {
    let title: String
    let subtitle: String?
    
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            
            Divider()
                .background(Color.black)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 15)
    }
}

// Common list item component with proper text handling
struct iPodListItem: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let showChevron: Bool
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isSelected: Bool = false,
        showChevron: Bool = true
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isSelected ? .white : .black)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            
            Spacer()
            
            if showChevron && isSelected {
                Image(systemName: "chevron.right")
                    .foregroundColor(isSelected ? .white : .black)
                    .font(.system(size: 12, weight: .bold))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(itemBackground)
    }
    
    private var itemBackground: LinearGradient {
        if isSelected {
            return LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
