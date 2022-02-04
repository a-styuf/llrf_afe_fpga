// megafunction wizard: %LPM_DIVIDE%VBB%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: LPM_DIVIDE 

// ============================================================
// File Name: divide_32.v
// Megafunction Name(s):
// 			LPM_DIVIDE
//
// Simulation Library Files(s):
// 			lpm
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 20.1.1 Build 720 11/11/2020 SJ Lite Edition
// ************************************************************

//Copyright (C) 2020  Intel Corporation. All rights reserved.
//Your use of Intel Corporation's design tools, logic functions 
//and other software and tools, and any partner logic 
//functions, and any output files from any of the foregoing 
//(including device programming or simulation files), and any 
//associated documentation or information are expressly subject 
//to the terms and conditions of the Intel Program License 
//Subscription Agreement, the Intel Quartus Prime License Agreement,
//the Intel FPGA IP License Agreement, or other applicable license
//agreement, including, without limitation, that your use is for
//the sole purpose of programming logic devices manufactured by
//Intel and sold by Intel or its authorized distributors.  Please
//refer to the applicable agreement for further details, at
//https://fpgasoftware.intel.com/eula.

module divide_32 (
	aclr,
	clken,
	clock,
	denom,
	numer,
	quotient,
	remain);

	input	  aclr;
	input	  clken;
	input	  clock;
	input	[63:0]  denom;
	input	[63:0]  numer;
	output	[63:0]  quotient;
	output	[63:0]  remain;

endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone 10 LP"
// Retrieval info: PRIVATE: PRIVATE_LPM_REMAINDERPOSITIVE STRING "TRUE"
// Retrieval info: PRIVATE: PRIVATE_MAXIMIZE_SPEED NUMERIC "6"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
// Retrieval info: PRIVATE: USING_PIPELINE NUMERIC "1"
// Retrieval info: PRIVATE: VERSION_NUMBER NUMERIC "2"
// Retrieval info: PRIVATE: new_diagram STRING "1"
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all
// Retrieval info: CONSTANT: LPM_DREPRESENTATION STRING "UNSIGNED"
// Retrieval info: CONSTANT: LPM_HINT STRING "MAXIMIZE_SPEED=6,LPM_REMAINDERPOSITIVE=TRUE"
// Retrieval info: CONSTANT: LPM_NREPRESENTATION STRING "UNSIGNED"
// Retrieval info: CONSTANT: LPM_PIPELINE NUMERIC "2"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_DIVIDE"
// Retrieval info: CONSTANT: LPM_WIDTHD NUMERIC "64"
// Retrieval info: CONSTANT: LPM_WIDTHN NUMERIC "64"
// Retrieval info: USED_PORT: aclr 0 0 0 0 INPUT NODEFVAL "aclr"
// Retrieval info: USED_PORT: clken 0 0 0 0 INPUT NODEFVAL "clken"
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL "clock"
// Retrieval info: USED_PORT: denom 0 0 64 0 INPUT NODEFVAL "denom[63..0]"
// Retrieval info: USED_PORT: numer 0 0 64 0 INPUT NODEFVAL "numer[63..0]"
// Retrieval info: USED_PORT: quotient 0 0 64 0 OUTPUT NODEFVAL "quotient[63..0]"
// Retrieval info: USED_PORT: remain 0 0 64 0 OUTPUT NODEFVAL "remain[63..0]"
// Retrieval info: CONNECT: @aclr 0 0 0 0 aclr 0 0 0 0
// Retrieval info: CONNECT: @clken 0 0 0 0 clken 0 0 0 0
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: CONNECT: @denom 0 0 64 0 denom 0 0 64 0
// Retrieval info: CONNECT: @numer 0 0 64 0 numer 0 0 64 0
// Retrieval info: CONNECT: quotient 0 0 64 0 @quotient 0 0 64 0
// Retrieval info: CONNECT: remain 0 0 64 0 @remain 0 0 64 0
// Retrieval info: GEN_FILE: TYPE_NORMAL divide_32.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL divide_32.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL divide_32.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL divide_32.bsf FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL divide_32_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL divide_32_bb.v TRUE
// Retrieval info: LIB_FILE: lpm