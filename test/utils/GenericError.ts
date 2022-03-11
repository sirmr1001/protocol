export enum ErrorCode {
  NO_ERROR,
  MARKET_NOT_LISTED,
  MARKET_ALREADY_LISTED,
  SNAPSHOT_ERROR,
  PRICE_ERROR,
  INSUFFICIENT_LIQUIDITY,
  INSUFFICIENT_SHORTFALL,
  AUDITOR_MISMATCH,
  TOO_MUCH_REPAY,
  REPAY_ZERO,
  TOKENS_MORE_THAN_BALANCE,
  INVALID_POOL_STATE,
  INVALID_POOL_ID,
  LIQUIDATOR_NOT_BORROWER,
  NOT_A_FIXED_LENDER_SENDER,
  INVALID_SET_BORROW_CAP,
  MARKET_BORROW_CAP_REACHED,
  INCONSISTENT_PARAMS_LENGTH,
  REDEEM_CANT_BE_ZERO,
  EXIT_MARKET_BALANCE_OWED,
  CALLER_MUST_BE_FIXED_LENDER,
  CONTRACT_ALREADY_INITIALIZED,
  INSUFFICIENT_PROTOCOL_LIQUIDITY,
  EXCEEDED_MAX_UTILIZATION_RATE,
  TOO_MUCH_SLIPPAGE,
  TOO_MUCH_REPAY_TRANSFER,
  SMART_POOL_FUNDS_LOCKED,
  INVALID_TIME_DIFFERENCE,
  INVALID_SP_FEE_RATE,
}

const GenericError = (code: ErrorCode) => `GenericError(${code})`;

export default GenericError;
