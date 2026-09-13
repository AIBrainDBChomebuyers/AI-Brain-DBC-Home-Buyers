// Constants both sides need to agree on. Duplicating these is how a frontend
// ends up offering a role the backend will reject.

// Section 9 of the technical document.
export const ROLES = Object.freeze([
  'executive', 'acquisitions', 'construction',
  'property_management', 'accounting', 'va',
]);

export const ROLE_LABELS = Object.freeze({
  executive: 'Owners / Executives',
  acquisitions: 'Acquisitions',
  construction: 'Construction',
  property_management: 'Property Management',
  accounting: 'Accounting',
  va: 'VAs / Other',
});

// What a row's sensitivity tier means, lowest to highest.
export const SENSITIVITY = Object.freeze(['internal', 'confidential', 'restricted']);

export const DEAL_STATUS = Object.freeze(['Sold', 'Active - acquired, not yet sold']);
export const EXIT_STRATEGIES = Object.freeze(['Fix and Flip', 'Wholesale', 'Wholetail', 'Listing']);
