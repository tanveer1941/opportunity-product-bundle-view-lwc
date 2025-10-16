# Opportunity Product Bundle View LWC

Repository: https://github.com/tanveer1941/opportunity-product-bundle-view-lwc

This Lightning Web Component displays OpportunityLineItems from synced Revenue Cloud Quotes in a structured format, showing bundle products with their nested children and standalone products at the end.

## Features

- Displays bundle products with nested child items in a hierarchical structure
- Shows standalone products separately at the end of the list
- Collapsible bundles by default
- Clean white background design
- Proper heading "Product Overview"
- Clear section separation for bundles and single products

## Component Structure

### Main Component
- `opportunityBundleView` - The primary LWC component

### Apex Classes
- `OpportunityBundleService` - Processes QuoteLineItems into hierarchical structure
- `OpportunityBundleServiceTest` - Test class with 100% coverage

## Installation

1. Deploy this project to your Salesforce org using SFDX or any preferred deployment method
2. Add the component to a page or record layout
3. Pass an Opportunity ID to the component via the `recordId` attribute

## Usage

The component expects an Opportunity ID to be passed as the `recordId` attribute. It will automatically fetch the related QuoteLineItems and display them appropriately.

## Customization

You can customize the following aspects:
- Heading text (currently "Product Overview")
- Section titles ("Bundles" and "Single Products")
- Styling in the CSS file
- Color schemes and visual hierarchy

## Dependencies

- Salesforce DX Project
- Lightning Web Components
- Apex classes for data processing
