// prom patches for debugging - nop out long loops

addr = ~9'o175 & 9'h1ff; cpu.i_PROM0.prom[addr] = 49'h000000001000;
addr = ~9'o202 & 9'h1ff; cpu.i_PROM0.prom[addr] = 49'h000000001000;
addr = ~9'o226 & 9'h1ff; cpu.i_PROM0.prom[addr] = 49'h000000001000;
addr = ~9'o232 & 9'h1ff; cpu.i_PROM0.prom[addr] = 49'h000000001000;
addr = ~9'o236 & 9'h1ff; cpu.i_PROM0.prom[addr] = 49'h000000001000;
addr = ~9'o244 & 9'h1ff; cpu.i_PROM0.prom[addr] = 49'h000000001000;
addr = ~9'o251 & 9'h1ff; cpu.i_PROM0.prom[addr] = 49'h000000001000;
addr = ~9'o256 & 9'h1ff; cpu.i_PROM0.prom[addr] = 49'h000000001000;
addr = ~9'o263 & 9'h1ff; cpu.i_PROM0.prom[addr] = 49'h000000001000;
addr = ~9'o314 & 9'h1ff; cpu.i_PROM0.prom[addr] = 49'h000000001000;

