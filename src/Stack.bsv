/**
 * Provide a basic functionality for LIFOs (Stacks).
 */
package Stack;

/**
 * An interface of Stack (LIFO) for universal types.
 */
interface Stack#(type data_t);
  /**
   * Push an element to the stack.
   * \param din Data to push.
   */
  method Action push(data_t din);
  /**
   * Pop an element from the stack.
   */
  method Action pop();
  /**
   * \return Top of the stack.
   */
  method data_t top();
  /**
   * \return True if the stack is empty.
   */
  (* always_ready *)
  method Bool empty();
  /**
   * \return True if the stack is full.
   */
  (* always_ready *)
  method Bool full();
endinterface

/**
 * A register-based stack implementation. The maximum size is 256.
 */
module mkStack#(Integer depth) (Stack#(data_t))
    provisos(Bits#(data_t, data_width_nt));

  Reg#(data_t) stack_mem_[depth];
  for (Integer i = 0; i < depth; i = i + 1)
    stack_mem_[i] <- mkRegU();

  StackSize size_ <- mkStackSize(depth);
  PulseWire pushing_ <- mkPulseWire();
  PulseWire popping_ <- mkPulseWire();
  Wire#(data_t) din_ <- mkWire();

  Bool full_ = size_.equal(depth);
  Bool empty_ = size_.equal(0);

  rule do_pushing (pushing_ && !popping_);
    size_.incr();
    stack_mem_[0] <= din_;
    for (Integer i = 1; i < depth; i = i + 1)
      stack_mem_[i] <= stack_mem_[i - 1];
  endrule

  rule do_popping (popping_ && !pushing_);
    size_.decr();
    for (Integer i = 1; i < depth; i = i + 1)
      stack_mem_[i - 1] <= stack_mem_[i];
  endrule

  rule do_pushing_popping (popping_ && pushing_);
    stack_mem_[0] <= din_;
  endrule

  method Action push(data_t din) if (!full_);
    pushing_.send();
    din_ <= din;
  endmethod

  method Action pop() if (!empty_);
    popping_.send();
  endmethod

  method data_t top() if (!empty_);
    return stack_mem_[0];
  endmethod

  method Bool empty() = empty_;
  method Bool full() = full_;
endmodule

interface StackSize;
  method Action incr();
  method Action decr();
  method Action clear();
  method Bool equal(Integer n);
endinterface

module _mkStackSize#(Reg#(UInt#(w)) c) (StackSize);
  method Action incr();
    c <= c + 1;
  endmethod

  method Action decr();
    c <= c - 1;
  endmethod

  method Action clear();
    c <= 0;
  endmethod

  method Bool equal(Integer n) = c == fromInteger(n);
endmodule

module mkStackSize#(Integer depth) (StackSize);
  StackSize s;
  if      (depth < (2 ** 1)) begin Reg#(UInt#(1)) r <- mkReg(0); s <- _mkStackSize(r); end
  else if (depth < (2 ** 2)) begin Reg#(UInt#(2)) r <- mkReg(0); s <- _mkStackSize(r); end
  else if (depth < (2 ** 3)) begin Reg#(UInt#(3)) r <- mkReg(0); s <- _mkStackSize(r); end
  else if (depth < (2 ** 4)) begin Reg#(UInt#(4)) r <- mkReg(0); s <- _mkStackSize(r); end
  else if (depth < (2 ** 5)) begin Reg#(UInt#(5)) r <- mkReg(0); s <- _mkStackSize(r); end
  else if (depth < (2 ** 6)) begin Reg#(UInt#(6)) r <- mkReg(0); s <- _mkStackSize(r); end
  else if (depth < (2 ** 7)) begin Reg#(UInt#(7)) r <- mkReg(0); s <- _mkStackSize(r); end
  else if (depth < (2 ** 8)) begin Reg#(UInt#(8)) r <- mkReg(0); s <- _mkStackSize(r); end
  else error("Cannot instantiate stack with depth larger than 256");
  return s;
endmodule

endpackage
