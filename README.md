# Options Trading Smart Contract

A decentralized options trading contract for the Stacks blockchain, enabling users to create, buy, exercise, and expire CALL and PUT options on SIP-010 tokens and STX.

## Features

- **Create Options**: Writers can issue CALL or PUT options with customizable parameters
- **Buy Options**: Buyers purchase options by paying the premium to the writer
- **Exercise Options**: Buyers execute in-the-money options with real-time price validation
- **Expire Options**: Automatic expiration handling for unexercised options past their expiration block height
- **Event Tracking**: Full event emission for option lifecycle monitoring

## Option Types

### CALL Option
- **Writer Perspective**: Receives premium upfront; collateral locked until expiration or exercise
- **Buyer Perspective**: Pays premium; profits when current price > strike price
- **Exercise**: Buyer pays `strike-price × amount` to acquire underlying asset

### PUT Option
- **Writer Perspective**: Receives premium upfront; obligated to pay if exercised
- **Buyer Perspective**: Pays premium; profits when current price < strike price
- **Exercise**: Writer pays `strike-price × amount` to buyer; buyer transfers underlying asset

## Smart Contract Functions

### Public Functions

#### `create-option`
Creates a new option contract.

**Parameters:**
- `option-type` (string-ascii 4): "CALL" or "PUT"
- `underlying` (principal): Token contract address
- `strike-price` (uint): Exercise price
- `amount` (uint): Number of contracts
- `premium` (uint): Price for buying the option
- `expiration` (uint): Block height when option expires

**Returns:** Option ID on success

#### `buy-option`
Buyer purchases an option by paying premium to writer.

**Parameters:**
- `id` (uint): Option ID

**Returns:** Success message on completion

#### `exercise-option`
Buyer executes an in-the-money option.

**Parameters:**
- `id` (uint): Option ID
- `current-price` (uint): Current market price of underlying asset

**Returns:** Success message on exercise completion

#### `expire-option`
Expires an unexercised option past its expiration block height.

**Parameters:**
- `id` (uint): Option ID

**Returns:** Success message on expiration

### Read-Only Functions

#### `get-option`
Retrieves option details.

**Parameters:**
- `id` (uint): Option ID

**Returns:** Option data or none

#### `get-option-count`
Gets the total number of options created.

**Returns:** Total option count

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | ERR_INVALID_TYPE | Invalid option type (not CALL or PUT) |
| 101 | ERR_ALREADY_BOUGHT | Option already purchased by another buyer |
| 404 | ERR_NOT_FOUND | Option ID does not exist |
| 105 | ERR_TOO_EARLY | Expiration has not been reached yet |
| 106 | ERR_EXPIRED | Option has expired |
| 107 | ERR_NOT_ITM | Option is not in-the-money |
| 108 | ERR_ALREADY_EXERCISED | Option already exercised |
| 109 | ERR_UNAUTHORIZED | Caller is not authorized |

## Data Structures

### Option Map
```
{
  writer: principal,           ;; Option creator
  buyer: optional principal,   ;; Option buyer
  option-type: string-ascii,   ;; "CALL" or "PUT"
  underlying: principal,       ;; Token contract
  strike-price: uint,          ;; Exercise price
  amount: uint,                ;; Number of contracts
  premium: uint,               ;; Buyer payment to writer
  expiration: uint,            ;; Block height expiration
  exercised: bool              ;; Exercise status
}
```

## Usage Examples

### Create a CALL Option
```clarity
(contract-call? .options-trading create-option "CALL" 'token-contract u50 u100 u1000 u12000)
```

### Buy an Option
```clarity
(contract-call? .options-trading buy-option u1)
```

### Exercise an Option
```clarity
(contract-call? .options-trading exercise-option u1 u55)
```

### Expire an Option
```clarity
(contract-call? .options-trading expire-option u1)
```

## Security Considerations

- ✅ Caller authentication for sensitive operations
- ✅ Prevention of double-purchase and re-exercise
- ✅ Expiration validation before exercise
- ✅ In-the-money (ITM) validation enforcement
- ✅ Immutable option records via map-set pattern
- ⚠️ Price oracle integration recommended for production

## Deployment

1. Clone the repository
2. Deploy contract to Stacks testnet or mainnet
3. Configure price oracle for `current-price` validation
4. Test all option workflows before production use

## Future Enhancements

- [ ] Oracle integration for automated price feeds
- [ ] Advanced fee mechanisms
- [ ] Multi-collateral support
- [ ] American vs European option styles
- [ ] Settlement via SIP-010 tokens instead of STX only
- [ ] Batch expiration functions
- [ ] Option portfolio tracking

## Author

GPT-5
