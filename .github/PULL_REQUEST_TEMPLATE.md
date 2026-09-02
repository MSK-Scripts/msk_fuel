# Pull Request

## Description

<!-- What does this PR change and why? -->

## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that changes existing behavior)
- [ ] Documentation update
- [ ] NUI change

## Related issues

<!-- Link any related issues, e.g. Closes #123 -->

## Testing

<!-- How did you test this in game? -->

- Areas touched:
  - [ ] Refueling / petrolcan
  - [ ] Fuel consumption / engine damage
  - [ ] Fuel business (ownership, pricing, stock, staff)
  - [ ] Supply and delivery jobs
  - [ ] Admin dashboard
  - [ ] NUI

## Checklist

- [ ] My code follows the style of the existing codebase
- [ ] Framework access goes through the msk_core bridge, not directly to ESX or QBCore
- [ ] Server-side validation is in place for anything triggered from the client
- [ ] New files are registered in `fxmanifest.lua` at the right spot of the load order
- [ ] New user facing strings are added to `translation.lua` for every existing language
- [ ] I rebuilt and committed `html/` if the NUI changed
- [ ] I updated `CHANGELOG.md` and the documentation if behavior, config or database schema changed
