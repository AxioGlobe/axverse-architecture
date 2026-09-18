#include "core/V1ToolRegistry.hpp"

#include <cstdlib>
#include <iostream>
#include <set>
#include <string>

namespace {

void Require(const bool condition, const std::string& message)
{
    if (!condition) {
        std::cerr << "FAIL: " << message << '\n';
        std::exit(EXIT_FAILURE);
    }
}

} // namespace

int main()
{
    using namespace AxioGlobe::Axverse;

    const ToolRegistry& tools = V1Tools();

    Require(tools.size() == 18, "V1 must contain exactly 18 tools.");
    Require(CountByCategory(ToolCategory::Design) == 6, "Design must contain 6 tools.");
    Require(CountByCategory(ToolCategory::Technical) == 5, "Technical must contain 5 tools.");
    Require(CountByCategory(ToolCategory::Documentation) == 7, "Documentation must contain 7 tools.");
    Require(CountBetaWaveOneTools() == 6, "Closed-beta wave one must contain exactly 6 tools.");

    std::set<std::string> ids;
    for (const ToolDescriptor& tool : tools) {
        Require(!tool.id.empty(), "Every V1 tool must have an id.");
        Require(!tool.name.empty(), "Every V1 tool must have a name.");
        Require(ids.emplace(tool.id).second, "V1 tool ids must be unique.");
        Require(FindToolById(tool.id) != nullptr, "Every registered tool must be discoverable by id.");
    }

    Require(FindToolById("product-dna-browser") != nullptr, "Product DNA Browser must be registered.");
    Require(FindToolById("living-object-placement") != nullptr, "Living Object Placement must be registered.");
    Require(FindToolById("product-compliance-check") != nullptr, "Product Compliance Check must be registered.");
    Require(FindToolById("specification-linker") != nullptr, "Specification Linker must be registered.");
    Require(FindToolById("schedule-validator") != nullptr, "Schedule Validator must be registered.");
    Require(FindToolById("publish-package") != nullptr, "Publish Package must be registered.");

    const NavigationRegistry& navigation = V1Navigation();
    Require(navigation.size() == 7, "Axverse V1 navigation must contain exactly 7 top-level entries.");
    Require(navigation[1].id == "design", "Design must remain a permanent top-level category.");
    Require(navigation[2].id == "technical", "Technical must remain a permanent top-level category.");
    Require(navigation[3].id == "documentation", "Documentation must remain a permanent top-level category.");

    std::cout << "PASS: Axverse V1 registry is valid (18 tools, 6/5/7 categories, 6 beta-wave-one tools).\n";
    return EXIT_SUCCESS;
}
