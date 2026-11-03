package adaptive_pkg;
  localparam int DATA_W = 8;
  localparam int ACC_W  = 24;
  localparam int CNT_W  = 16;

  typedef enum logic [2:0] {
    MODE_NORMAL    = 3'd0,
    MODE_MONITOR   = 3'd1,
    MODE_THROTTLE  = 3'd2,
    MODE_RECOVER   = 3'd3,
    MODE_LOW_POWER = 3'd4
  } mode_e;
endpackage
