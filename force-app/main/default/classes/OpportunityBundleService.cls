public with sharing class OpportunityBundleService {
    public class LineItemDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String productName;
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Decimal totalPrice;
        @AuraEnabled public List<LineItemDTO> children;

        public LineItemDTO() {
            children = new List<LineItemDTO>();
        }
    }

    public class BundleResponse {
        @AuraEnabled public List<LineItemDTO> bundles;
        @AuraEnabled public List<LineItemDTO> standalone;

        public BundleResponse() {
            bundles = new List<LineItemDTO>();
            standalone = new List<LineItemDTO>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static BundleResponse getQuoteBundleTree(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('opportunityId is required');
        }

        // Get synced quote
        Id syncedQuoteId = [
            SELECT SyncedQuoteId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ].SyncedQuoteId;

        if (syncedQuoteId == null) {
            // No synced quote - return empty result
            return new BundleResponse();
        }

        // Query Quote Line Items including parent linkage.
        // Note: ParentQuoteLineItemId is assumed per user feedback.
        List<QuoteLineItem> qlis = [
            SELECT Id,
                   QuoteId,
                   Product2Id,
                   Product2.Name,
                   Product2.ProductCode,
                   Quantity,
                   UnitPrice,
                   TotalPrice,
                   ListPrice,
                   ParentQuoteLineItemId,
                   CreatedDate
            FROM QuoteLineItem
            WHERE QuoteId = :syncedQuoteId
        ];

        // Build map of DTOs
        Map<Id, LineItemDTO> dtoById = new Map<Id, LineItemDTO>();
        // Temporary holding of parent relationships
        Map<Id, List<LineItemDTO>> childrenByParent = new Map<Id, List<LineItemDTO>>();

        for (QuoteLineItem qli : qlis) {
            LineItemDTO dto = new LineItemDTO();
            dto.id = qli.Id;
            dto.productName = (qli.Product2 != null ? qli.Product2.Name : null);
            dto.productCode = (qli.Product2 != null ? qli.Product2.ProductCode : null);
            dto.quantity = qli.Quantity;
            dto.unitPrice = qli.UnitPrice;
            dto.totalPrice = qli.TotalPrice;
            // QuoteLineItem does not expose CurrencyIsoCode as a field in all orgs.
            // Derive from parent Quote if needed.
            dtoById.put(qli.Id, dto);

            if (qli.ParentQuoteLineItemId != null) {
                if (!childrenByParent.containsKey(qli.ParentQuoteLineItemId)) {
                    childrenByParent.put(qli.ParentQuoteLineItemId, new List<LineItemDTO>());
                }
                childrenByParent.get(qli.ParentQuoteLineItemId).add(dto);
            }
        }

        // Identify top-level lines (no parent)
        Set<Id> childIds = new Set<Id>();
        for (Id parentId : childrenByParent.keySet()) {
            for (LineItemDTO c : childrenByParent.get(parentId)) {
                childIds.add(c.id);
            }
        }

        List<LineItemDTO> topLevel = new List<LineItemDTO>();
        for (QuoteLineItem qli : qlis) {
            if (!childIds.contains(qli.Id)) {
                topLevel.add(dtoById.get(qli.Id));
            }
        }

        // Attach children to parents
        for (Id parentId : childrenByParent.keySet()) {
            LineItemDTO parent = dtoById.get(parentId);
            if (parent != null) {
                // Sort children alphabetically by productName
                List<LineItemDTO> kids = childrenByParent.get(parentId);
                kids.sort(new LineItemNameComparator());
                parent.children.addAll(kids);
            }
        }

        // Prepare response:
        // - Any top-level item that has children is a bundle.
        // - Any top-level item that has no children is standalone.
        // - Children are already attached and sorted alphabetically.
        BundleResponse resp = new BundleResponse();

        // Sort top-level bundles alphabetically, and standalone alphabetically as requested UX polish.
        List<LineItemDTO> bundleTop = new List<LineItemDTO>();
        List<LineItemDTO> standaloneTop = new List<LineItemDTO>();

        for (LineItemDTO tl : topLevel) {
            if (tl.children != null && !tl.children.isEmpty()) {
                bundleTop.add(tl);
            } else {
                standaloneTop.add(tl);
            }
        }

        bundleTop.sort(new LineItemNameComparator());
        standaloneTop.sort(new LineItemNameComparator());

        resp.bundles.addAll(bundleTop);
        resp.standalone.addAll(standaloneTop);

        return resp;
    }

    // Comparator to sort by productName (case-insensitive), nulls last, then by productCode.
    public class LineItemNameComparator implements System.Comparator<LineItemDTO> {
        public Integer compare(LineItemDTO a, LineItemDTO b) {
            String an = a != null ? (a.productName != null ? a.productName.toLowerCase() : null) : null;
            String bn = b != null ? (b.productName != null ? b.productName.toLowerCase() : null) : null;

            if (an == bn) {
                // both null or same ref
                return compareByCode(a, b);
            }
            if (an == null) return 1; // nulls last
            if (bn == null) return -1;

            Integer byName = an.compareTo(bn);
            if (byName != 0) return byName;

            return compareByCode(a, b);
        }

        private Integer compareByCode(LineItemDTO a, LineItemDTO b) {
            String ac = a != null ? a.productCode : null;
            String bc = b != null ? b.productCode : null;
            if (ac == bc) return 0;
            if (ac == null) return 1;
            if (bc == null) return -1;
            // Apex String doesn't have compareToIgnoreCase; compare using lowercase.
            return ac.toLowerCase().compareTo(bc.toLowerCase());
        }
    }
}
