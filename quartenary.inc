; quartenary.inc
; Foundation for Quartenary System
; Values: 0 (Null/Mati), 1 (True), 4 (Quo/Ambigu), 8 (Cert/Pasti)

%ifndef QUARTENARY_INC
%define QUARTENARY_INC

; --- Constants ---
%define Q_NULL  0
%define Q_TRUE  1
%define Q_QUO   4
%define Q_CERT  8

; --- Macros ---

; Macro to align the following data to 16 bytes (User requirement: alignment kelipatan 16)
%macro Q_ALIGN_16 0
    align 16
%endmacro

; Macro to define a "Quo" block structure
; User mentioned "4 snapshot memory (4 magic header)"
; We will define a structure that reserves space and ensures alignment
struc QuoBlock
    .header: resq 1   ; 8 bytes for header/value
    .meta:   resq 1   ; 8 bytes for metadata (total 16 bytes for alignment)
endstruc

%endif
