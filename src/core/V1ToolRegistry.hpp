#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <string_view>

namespace AxioGlobe::Axverse {

enum class ToolCategory : std::uint8_t {
    Design,
    Technical,
    Documentation
};

struct ToolDescriptor {
    std::string_view id;
    std::string_view name;
    ToolCategory category;
    bool betaWaveOne;
};

struct NavigationItem {
    std::string_view id;
    std::string_view label;
};

inline constexpr std::size_t kV1ToolCount = 18;
inline constexpr std::size_t kV1NavigationCount = 7;

using ToolRegistry = std::array<ToolDescriptor, kV1ToolCount>;
using NavigationRegistry = std::array<NavigationItem, kV1NavigationCount>;

const ToolRegistry& V1Tools() noexcept;
const NavigationRegistry& V1Navigation() noexcept;

std::size_t CountByCategory(ToolCategory category) noexcept;
std::size_t CountBetaWaveOneTools() noexcept;

const ToolDescriptor* FindToolById(std::string_view id) noexcept;

} // namespace AxioGlobe::Axverse
