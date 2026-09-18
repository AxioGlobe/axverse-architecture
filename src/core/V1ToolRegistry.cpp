#include "core/V1ToolRegistry.hpp"

namespace AxioGlobe::Axverse {
namespace {

constexpr ToolRegistry kTools {{
    {"product-dna-browser", "Product DNA Browser", ToolCategory::Design, true},
    {"living-object-placement", "Living Object Placement", ToolCategory::Design, true},
    {"smart-product-substitute", "Smart Product Substitute", ToolCategory::Design, false},
    {"wall-assembly-builder", "Wall Assembly Builder", ToolCategory::Design, false},
    {"smart-openings", "Smart Openings", ToolCategory::Design, false},
    {"space-planner-assist", "Space Planner Assist", ToolCategory::Design, false},

    {"model-health-check", "Model Health Check", ToolCategory::Technical, false},
    {"accessibility-checker", "Accessibility Checker", ToolCategory::Technical, false},
    {"daylight-preview", "Daylight Preview", ToolCategory::Technical, false},
    {"clearance-checker", "Clearance Checker", ToolCategory::Technical, false},
    {"product-compliance-check", "Product Compliance Check", ToolCategory::Technical, true},

    {"smart-annotation", "Smart Annotation", ToolCategory::Documentation, false},
    {"smart-dimensioning", "Smart Dimensioning", ToolCategory::Documentation, false},
    {"drawing-coordinator", "Drawing Coordinator", ToolCategory::Documentation, false},
    {"schedule-validator", "Schedule Validator", ToolCategory::Documentation, true},
    {"specification-linker", "Specification Linker", ToolCategory::Documentation, true},
    {"issue-snapshot", "Issue Snapshot", ToolCategory::Documentation, false},
    {"publish-package", "Publish Package", ToolCategory::Documentation, true}
}};

constexpr NavigationRegistry kNavigation {{
    {"home-project-pulse", "Home / Project Pulse"},
    {"design", "Design"},
    {"technical", "Technical"},
    {"documentation", "Documentation"},
    {"peer", "PEER"},
    {"opportunities", "Opportunities"},
    {"notifications", "Notifications"}
}};

} // namespace

const ToolRegistry& V1Tools() noexcept
{
    return kTools;
}

const NavigationRegistry& V1Navigation() noexcept
{
    return kNavigation;
}

std::size_t CountByCategory(const ToolCategory category) noexcept
{
    std::size_t count = 0;

    for (const ToolDescriptor& tool : kTools) {
        if (tool.category == category) {
            ++count;
        }
    }

    return count;
}

std::size_t CountBetaWaveOneTools() noexcept
{
    std::size_t count = 0;

    for (const ToolDescriptor& tool : kTools) {
        if (tool.betaWaveOne) {
            ++count;
        }
    }

    return count;
}

const ToolDescriptor* FindToolById(const std::string_view id) noexcept
{
    for (const ToolDescriptor& tool : kTools) {
        if (tool.id == id) {
            return &tool;
        }
    }

    return nullptr;
}

} // namespace AxioGlobe::Axverse
