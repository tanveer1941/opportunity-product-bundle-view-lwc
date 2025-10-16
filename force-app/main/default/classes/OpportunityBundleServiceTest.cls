@IsTest
private class OpportunityBundleServiceTest {
    @IsTest
    static void testGetQuoteBundleTree_nullInput() {
        // Test null input
        try {
            OpportunityBundleService.getQuoteBundleTree(null);
            System.assert(false, 'Expected exception when opportunityId is null');
        } catch (AuraHandledException e) {
            // Expected exception
            System.assert(e != null, 'Should throw AuraHandledException when opportunityId is null');
        }
    }

    @IsTest
    static void testGetQuoteBundleTree_emptyWhenNoSyncedQuote() {
        // Create an Opp without a synced Quote
        Account acc = new Account(Name = 'No Quote Acc');
        insert acc;

        Opportunity opp2 = new Opportunity(
            Name = 'Opp Without Synced Quote',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp2;

        Test.startTest();
        OpportunityBundleService.BundleResponse resp = OpportunityBundleService.getQuoteBundleTree(opp2.Id);
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null for no-synced case');
        System.assertEquals(0, resp.bundles.size(), 'No bundles expected');
        System.assertEquals(0, resp.standalone.size(), 'No standalone expected');
    }

    @IsTest
    static void testGetQuoteBundleTree_withSyncedQuoteButNoItems() {
        // Create account and opportunity with synced quote
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        // Create a quote and link it to the opportunity
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Active'
        );
        insert quote;

        // Update opportunity to sync the quote
        opp.SyncedQuoteId = quote.Id;
        update opp;

        Test.startTest();
        OpportunityBundleService.BundleResponse resp = OpportunityBundleService.getQuoteBundleTree(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals(0, resp.bundles.size(), 'No bundles expected');
        System.assertEquals(0, resp.standalone.size(), 'No standalone expected');
    }

    @IsTest
    static void testLineItemNameComparator() {
        OpportunityBundleService.LineItemNameComparator comparator = new OpportunityBundleService.LineItemNameComparator();
        
        // Test null comparison
        Integer result = comparator.compare(null, null);
        System.assertEquals(0, result, 'Comparing null to null should return 0');
        
        // Test null vs non-null
        OpportunityBundleService.LineItemDTO a = new OpportunityBundleService.LineItemDTO();
        OpportunityBundleService.LineItemDTO b = new OpportunityBundleService.LineItemDTO();
        b.productName = 'Test';
        
        result = comparator.compare(a, b);
        System.assertEquals(1, result, 'Null should come after non-null');
        
        result = comparator.compare(b, a);
        System.assertEquals(-1, result, 'Non-null should come before null');
        
        // Test simple string comparison
        a.productName = 'Alpha';
        b.productName = 'Beta';
        result = comparator.compare(a, b);
        System.assertEquals(-1, result, 'Alpha should come before Beta');
        
        result = comparator.compare(b, a);
        System.assertEquals(1, result, 'Beta should come after Alpha');
        
        // Test equal strings
        a.productName = 'Same';
        b.productName = 'Same';
        result = comparator.compare(a, b);
        System.assertEquals(0, result, 'Equal strings should return 0');
    }
}
