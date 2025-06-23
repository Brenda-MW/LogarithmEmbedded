function [x,n] = fi_normalize_unsigned_8_bit_byte(u)
    assert(isscalar(u),'Input must be scalar');
    assert(all(u>0),'Input must be positive.');
    assert(isfi(u) && isfixed(u),'Input must be a fi object with fixed-point data type.');
    u = removefimath(u);
    NLZLUT = number_of_leading_zeros_look_up_table();
    word_length = u.WordLength;
    u_fraction_length = u.FractionLength;
    B = 8;
    leftshifts=int8(0);
    % Reinterpret the input as an unsigned integer.
    T_unsigned_integer = numerictype(0, word_length, 0);
    v = reinterpretcast(u,T_unsigned_integer);
    F = fimath('OverflowAction','Wrap',...
               'RoundingMethod','Floor',...
               'SumMode','KeepLSB',...
               'SumWordLength',v.WordLength);
    v = setfimath(v,F);
    % Unroll the loop in generated code so there will be no branching.
    for k = coder.unroll(1:ceil(word_length/B))
        % For each iteration, see how many leading zeros are in the high
        % byte of V, and shift them out to the left. Continue with the
        % shifted V for as many bytes as it has.
        %
        % The index is the high byte of the input plus 1 to make it a
        % one-based index.
        index = int32(bitsra(v,word_length-B) + uint8(1));
        % Index into the number-of-leading-zeros lookup table.  This lookup
        % table takes in a byte and returns the number of leading zeros in the
        % binary representation.
        shiftamount = NLZLUT(index);
        % Left-shift out all the leading zeros in the high byte.
        v = bitsll(v,shiftamount);
        % Update the total number of left-shifts
        leftshifts = leftshifts+shiftamount;
    end
    % The input has been left-shifted so the most-significant-bit is a 1.
    % Reinterpret the output as unsigned with one integer bit, so
    % that 1 <= x < 2.
    T_x = numerictype(0,word_length,word_length-1);
    x = reinterpretcast(v,T_x);
    x = removefimath(x);
    % Let Q = int(u).  Then u = Q*2^(-u_fraction_length),
    % and x = Q*2^leftshifts * 2^(1-word_length).  Therefore,
    % u = x*2^n, where n is defined as:
    n = word_length -  u_fraction_length - leftshifts - 1;
end