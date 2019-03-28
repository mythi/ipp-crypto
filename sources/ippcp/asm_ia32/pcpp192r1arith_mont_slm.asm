;===============================================================================
; Copyright 2016-2019 Intel Corporation
; All Rights Reserved.
;
; If this  software was obtained  under the  Intel Simplified  Software License,
; the following terms apply:
;
; The source code,  information  and material  ("Material") contained  herein is
; owned by Intel Corporation or its  suppliers or licensors,  and  title to such
; Material remains with Intel  Corporation or its  suppliers or  licensors.  The
; Material  contains  proprietary  information  of  Intel or  its suppliers  and
; licensors.  The Material is protected by  worldwide copyright  laws and treaty
; provisions.  No part  of  the  Material   may  be  used,  copied,  reproduced,
; modified, published,  uploaded, posted, transmitted,  distributed or disclosed
; in any way without Intel's prior express written permission.  No license under
; any patent,  copyright or other  intellectual property rights  in the Material
; is granted to  or  conferred  upon  you,  either   expressly,  by implication,
; inducement,  estoppel  or  otherwise.  Any  license   under such  intellectual
; property rights must be express and approved by Intel in writing.
;
; Unless otherwise agreed by Intel in writing,  you may not remove or alter this
; notice or  any  other  notice   embedded  in  Materials  by  Intel  or Intel's
; suppliers or licensors in any way.
;
;
; If this  software  was obtained  under the  Apache License,  Version  2.0 (the
; "License"), the following terms apply:
;
; You may  not use this  file except  in compliance  with  the License.  You may
; obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
;
;
; Unless  required  by   applicable  law  or  agreed  to  in  writing,  software
; distributed under the License  is distributed  on an  "AS IS"  BASIS,  WITHOUT
; WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;
; See the   License  for the   specific  language   governing   permissions  and
; limitations under the License.
;===============================================================================

;
;
;     Purpose:  Cryptography Primitive.
;               P192r1 basic arithmetic function
;
;     Content:
;      p192r1_add
;      p192r1_sub
;      p192r1_neg
;      p192r1_div_by_2
;      p192r1_mul_mont_slm
;      p192r1_sqr_mont_slm
;      p192r1_mred
;      p192r1_select_pp_w5
;      p192r1_select_ap_w7
;

.686P
.387
.XMM
.MODEL FLAT,C

include asmdefs.inc
include ia_emm.inc
include pcpvariant.inc

IF (_IPP GE _IPP_P8)

IFDEF IPP_PIC
LD_ADDR MACRO reg:REQ, addr:REQ
LOCAL LABEL
        call     LABEL
LABEL:  pop      reg
        sub      reg, LABEL-addr
ENDM
ELSE
LD_ADDR MACRO reg:REQ, addr:REQ
        lea      reg, addr
ENDM
ENDIF


IPPCODE SEGMENT 'CODE' ALIGN (IPP_ALIGN_FACTOR)

;;
;; some p384r1 constants
;;
p192r1_data:
_prime192r1 DD 0FFFFFFFFh,0FFFFFFFFh,0FFFFFFFEh,0FFFFFFFFh,0FFFFFFFFh,0FFFFFFFFh

LEN192 = (192/32) ; dword's length of operands

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Ipp32u add_192(Ipp32u* r, const Ipp32u* a, const Ipp32u* b)
;;
;; input:   edi = r
;;          esi = a
;;          ebx = b
;;
;; output:  eax = carry = 0/1
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM add_192 PROC NEAR PRIVATE
      ; r = a+b
      mov   eax, dword ptr[esi]
      add   eax, dword ptr[ebx]
      mov   dword ptr[edi], eax

      mov   eax, dword ptr[esi+sizeof(dword)]
      adc   eax, dword ptr[ebx+sizeof(dword)]
      mov   dword ptr[edi+sizeof(dword)], eax

      mov   eax, dword ptr[esi+sizeof(dword)*2]
      adc   eax, dword ptr[ebx+sizeof(dword)*2]
      mov   dword ptr[edi+sizeof(dword)*2], eax

      mov   eax, dword ptr[esi+sizeof(dword)*3]
      adc   eax, dword ptr[ebx+sizeof(dword)*3]
      mov   dword ptr[edi+sizeof(dword)*3], eax

      mov   eax, dword ptr[esi+sizeof(dword)*4]
      adc   eax, dword ptr[ebx+sizeof(dword)*4]
      mov   dword ptr[edi+sizeof(dword)*4], eax

      mov   eax, dword ptr[esi+sizeof(dword)*5]
      adc   eax, dword ptr[ebx+sizeof(dword)*5]
      mov   dword ptr[edi+sizeof(dword)*5], eax

      mov   eax, 0
      adc   eax, 0
      ret
IPPASM add_192 ENDP

;;
;; Ipp32u sub_192(Ipp32u* r, const Ipp32u* a, const Ipp32u* b)
;;
;; input:   edi = r
;;          esi = a
;;          ebx = b
;;
;; output:  eax = borrow = 0/1
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM sub_192 PROC NEAR PRIVATE
      ; r = a-b
      mov   eax, dword ptr[esi]
      sub   eax, dword ptr[ebx]
      mov   dword ptr[edi], eax

      mov   eax, dword ptr[esi+sizeof(dword)]
      sbb   eax, dword ptr[ebx+sizeof(dword)]
      mov   dword ptr[edi+sizeof(dword)], eax

      mov   eax, dword ptr[esi+sizeof(dword)*2]
      sbb   eax, dword ptr[ebx+sizeof(dword)*2]
      mov   dword ptr[edi+sizeof(dword)*2], eax

      mov   eax, dword ptr[esi+sizeof(dword)*3]
      sbb   eax, dword ptr[ebx+sizeof(dword)*3]
      mov   dword ptr[edi+sizeof(dword)*3], eax

      mov   eax, dword ptr[esi+sizeof(dword)*4]
      sbb   eax, dword ptr[ebx+sizeof(dword)*4]
      mov   dword ptr[edi+sizeof(dword)*4], eax

      mov   eax, dword ptr[esi+sizeof(dword)*5]
      sbb   eax, dword ptr[ebx+sizeof(dword)*5]
      mov   dword ptr[edi+sizeof(dword)*5], eax

      mov   eax, 0
      adc   eax, 0
      ret
IPPASM sub_192 ENDP

;;
;; Ipp32u shl_192(Ipp32u* r, const Ipp32u* a)
;;
;; input:   edi = r
;;          esi = a
;;
;; output:  eax = extension = 0/1
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM shl_192 PROC NEAR PRIVATE
      mov      eax, dword ptr[esi+(LEN192-1)*sizeof(dword)]
      ; r = a<<1
      movq     xmm2, qword ptr[esi+sizeof(oword)]
      movdqu   xmm1, oword ptr[esi]

      movdqa   xmm3, xmm2
      palignr  xmm3, xmm1, sizeof(qword)
      psllq    xmm2, 1
      psrlq    xmm3, 63
      por      xmm2, xmm3
      movq     qword ptr[edi+sizeof(oword)], xmm2

      movdqa   xmm3, xmm1
      pslldq   xmm3, sizeof(qword)
      psllq    xmm1, 1
      psrlq    xmm3, 63
      por      xmm1, xmm3
      movdqu   oword ptr[edi], xmm1

      shr     eax, 31
      ret
IPPASM shl_192 ENDP

;;
;; void shr_192(Ipp32u* r, const Ipp32u* a)
;;
;; input:   edi = r
;;          esi = a
;;          eax = ext
;; output:  eax = extension = 0/1
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM shr_192 PROC NEAR PRIVATE
      ; r = a>>1
      movdqu   xmm2, oword ptr[esi]
      movq     xmm1, qword ptr[esi+sizeof(oword)]

      movdqa   xmm3, xmm1
      palignr  xmm3, xmm2, sizeof(qword)
      psrlq    xmm2, 1
      psllq    xmm3, 63
      por      xmm2, xmm3
      movdqu   oword ptr[edi], xmm2

      movdqa   xmm3, xmm0
      psrlq    xmm1, 1
      psllq    xmm3, 63
      por      xmm1, xmm3
      movq     qword ptr[edi+sizeof(oword)], xmm1

      ret
IPPASM shr_192 ENDP

;;
;; void cpy_192(Ipp32u* r, const Ipp32u* a)
;;
cpy_192 MACRO pdst:REQ,psrc:REQ
   movdqu   xmm0, oword ptr[psrc]
   movq     xmm1, qword ptr[psrc+sizeof(oword)]
   movdqu   oword ptr[pdst], xmm0
   movq     qword ptr[pdst+sizeof(oword)], xmm1
ENDM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; void p192r1_add(Ipp32u* r, const Ipp32u* a, const Ipp32u* b)
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM p192r1_add PROC NEAR C PUBLIC \
      USES esi edi ebx,\
      pR:   PTR DWORD,\  ; product address
      pA:   PTR DWORD,\  ; source A address
      pB:   PTR DWORD   ; source B address
;
; stack layout:
;
_buf_  = 0                             ; buffer[LEN192]
_sp_   = _buf_+(LEN192)*sizeof(dword)  ; esp[1]
_frame_= _sp_ +sizeof(dword)           ; +16 bytes for alignment

      mov   eax, esp                   ; save esp
      sub   esp, _frame_               ; allocate frame
      and   esp, -16                   ; provide 16-byte alignment
      mov   dword ptr[esp+_sp_], eax   ; store esp

      mov      edi, pR                 ; pR
      mov      esi, pA                 ; pA
      mov      ebx, pB                 ; pB
      CALLASM  add_192                 ; R = A+B
      mov      edx, eax

      lea      edi, [esp+_buf_]        ; T
      mov      esi, pR                 ; R
      LD_ADDR  ebx, p192r1_data        ; modulus
      lea      ebx, dword ptr[ebx+(_prime192r1-p192r1_data)]
      CALLASM  sub_192                 ; T = R-modulus

      lea      esi,[esp+_buf_]
      mov      edi, pR
      sub      edx, eax                ; R = T<0? R : T
      cmovnz   esi, edi
      cpy_192  edi, esi

      mov      esp, [esp+_sp_]
      ret
IPPASM p192r1_add ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; void p192r1_sub(Ipp32u* r, const Ipp32u* a, const Ipp32u* b)
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM p192r1_sub PROC NEAR C PUBLIC \
      USES esi edi ebx,\
      pR:   PTR DWORD,\  ; product address
      pA:   PTR DWORD,\  ; source A address
      pB:   PTR DWORD   ; source B address
;
; stack layout:
;
_buf_  = 0                             ; buffer[LEN192]
_sp_   = _buf_+(LEN192)*sizeof(dword)  ; esp[1]
_frame_= _sp_ +sizeof(dword)           ; +16 bytes for alignment

      mov   eax, esp                   ; save esp
      sub   esp, _frame_               ; allocate frame
      and   esp, -16                   ; provide 16-byte alignment
      mov   dword ptr[esp+_sp_], eax   ; store esp

      mov      edi, pR                 ; pR
      mov      esi, pA                 ; pA
      mov      ebx, pB                 ; pB
      CALLASM  sub_192                 ; R = A-B
      mov      edx, eax

      lea      edi, [esp+_buf_]        ; T
      mov      esi, pR                 ; R
      LD_ADDR  ebx, p192r1_data        ; modulus
      lea      ebx, dword ptr[ebx+(_prime192r1-p192r1_data)]
      CALLASM  add_192                 ; T = R+modulus

      lea      esi,[esp+_buf_]
      mov      edi, pR
      test     edx, edx                ; R = T<0? R : T
      cmovz    esi, edi
      cpy_192  edi, esi

      mov      esp, [esp+_sp_]
      ret
IPPASM p192r1_sub ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; void p192r1_neg(Ipp32u* r, const Ipp32u* a)
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM p192r1_neg PROC NEAR C PUBLIC \
      USES esi edi ebx,\
      pR:   PTR DWORD,\  ; product address
      pA:   PTR DWORD   ; source A address
;
; stack layout:
;
_buf_  = 0                             ; buffer[LEN192]
_sp_   = _buf_+(LEN192)*sizeof(dword)  ; esp[1]
_frame_= _sp_ +sizeof(dword)           ; +16 bytes for alignment

      mov   eax, esp                   ; save esp
      sub   esp, _frame_               ; allocate frame
      and   esp, -16                   ; provide 16-byte alignment
      mov   dword ptr[esp+_sp_], eax   ; store esp

      mov   edi, pR                    ; outpur pR
      mov   esi, pA                    ; input pA

      ; r = 0-a
      mov   eax, 0
      sub   eax, dword ptr[esi]
      mov   dword ptr[edi], eax
      mov   eax, 0
      sbb   eax, dword ptr[esi+sizeof(dword)]
      mov   dword ptr[edi+sizeof(dword)], eax
      mov   eax, 0
      sbb   eax, dword ptr[esi+sizeof(dword)*2]
      mov   dword ptr[edi+sizeof(dword)*2], eax
      mov   eax, 0
      sbb   eax, dword ptr[esi+sizeof(dword)*3]
      mov   dword ptr[edi+sizeof(dword)*3], eax
      mov   eax, 0
      sbb   eax, dword ptr[esi+sizeof(dword)*4]
      mov   dword ptr[edi+sizeof(dword)*4], eax
      mov   eax, 0
      sbb   eax, dword ptr[esi+sizeof(dword)*5]
      mov   dword ptr[edi+sizeof(dword)*5], eax
      sbb   edx,edx

      lea      edi, [esp+_buf_]        ; T
      mov      esi, pR                 ; R
      LD_ADDR  ebx, p192r1_data        ; modulus
      lea      ebx, dword ptr[ebx+(_prime192r1-p192r1_data)]
      CALLASM  add_192                 ; T = R+modulus

      lea      esi,[esp+_buf_]
      mov      edi, pR
      test     edx, edx                ; R = T<0? R : T
      cmovz    esi, edi
      cpy_192  edi, esi

      mov      esp, [esp+_sp_]
      ret
IPPASM p192r1_neg ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; void p192r1_mul_by_2(Ipp32u* r, const Ipp32u* a)
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM p192r1_mul_by_2 PROC NEAR C PUBLIC \
      USES esi edi ebx,\
      pR:   PTR DWORD,\  ; product address
      pA:   PTR DWORD   ; source A address
;
; stack layout:
;
_buf_  = 0                             ; buffer[LEN192]
_sp_   = _buf_+(LEN192)*sizeof(dword)  ; esp[1]
_frame_= _sp_ +sizeof(dword)           ; +16 bytes for alignment

      mov   eax, esp                   ; save esp
      sub   esp, _frame_               ; allocate frame
      and   esp, -16                   ; provide 16-byte alignment
      mov   dword ptr[esp+_sp_], eax   ; store esp

      lea      edi, [esp+_buf_]        ; T
      mov      esi, pA                 ; pA
      CALLASM  shl_192                 ; T = A<<1
      mov      edx, eax

      mov      esi, edi                ; T
      mov      edi, pR                 ; R
      LD_ADDR  ebx, p192r1_data        ; modulus
      lea      ebx, dword ptr[ebx+(_prime192r1-p192r1_data)]
      CALLASM  sub_192                 ; R = T-modulus

      sub      edx, eax                ; R = R<0? T : R
      cmovz    esi, edi
      cpy_192  edi, esi

      mov      esp, [esp+_sp_]
      ret
IPPASM p192r1_mul_by_2 ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; void p192r1_mul_by_3(Ipp32u* r, const Ipp32u* a)
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM p192r1_mul_by_3 PROC NEAR C PUBLIC \
      USES esi edi ebx,\
      pR:   PTR DWORD,\  ; product address
      pA:   PTR DWORD   ; source A address
;
; stack layout:
;
_bufT_ = 0                             ; T buffer[LEN192]
_bufU_ = _bufT_+(LEN192)*sizeof(dword) ; U buffer[LEN192]
_mod_  = _bufU_+(LEN192)*sizeof(dword) ; modulus address [1]
_sp_   = _mod_+sizeof(dword)           ; esp [1]
_frame_= _sp_ +sizeof(dword)           ; +16 bytes for alignment

      mov   eax, esp                   ; save esp
      sub   esp, _frame_               ; allocate frame
      and   esp, -16                   ; provide 16-byte alignment
      mov   dword ptr[esp+_sp_], eax   ; store esp

      LD_ADDR  eax, p192r1_data        ; srore modulus address
      lea      eax, dword ptr[eax+(_prime192r1-p192r1_data)]
      mov      dword ptr[esp+_mod_], eax

      lea      edi, [esp+_bufT_]       ; T
      mov      esi, pA                 ; A
      CALLASM  shl_192                 ; T = A<<1
      mov      edx, eax

      mov      esi, edi                ; T
      lea      edi, [esp+_bufU_]       ; U
      mov      ebx, [esp+_mod_]        ; modulus
      CALLASM  sub_192                 ; U = T-modulus

      sub      edx, eax                ; T = U<0? T : U
      cmovz    esi, edi
      cpy_192  edi, esi

      mov      esi, edi
      mov      ebx, pA
      CALLASM  add_192                 ; T +=A
      mov      edx, eax

      mov      edi, pR                 ; R
      mov      ebx, [esp+_mod_]        ; modulus
      CALLASM  sub_192                 ; R = T-modulus

      sub      edx, eax                ; R = T<0? R : T
      cmovz    esi, edi
      cpy_192  edi, esi

      mov      esp, [esp+_sp_]
      ret
IPPASM p192r1_mul_by_3 ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; void p192r1_div_by_2(Ipp32u* r, const Ipp32u* a)
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM p192r1_div_by_2 PROC NEAR C PUBLIC \
      USES esi edi ebx,\
      pR:   PTR DWORD,\  ; product address
      pA:   PTR DWORD   ; source A address
;
; stack layout:
;
_buf_  = 0                             ; buffer[LEN192]
_sp_   = _buf_+(LEN192)*sizeof(dword)  ; esp[1]
_frame_= _sp_ +sizeof(dword)           ; +16 bytes for alignment

      mov   eax, esp                   ; save esp
      sub   esp, _frame_               ; allocate frame
      and   esp, -16                   ; provide 16-byte alignment
      mov   dword ptr[esp+_sp_], eax   ; store esp

      lea      edi, [esp+_buf_]        ; T
      mov      esi, pA                 ; A
      LD_ADDR  ebx, p192r1_data        ; modulus
      lea      ebx, dword ptr[ebx+(_prime192r1-p192r1_data)]
      CALLASM  add_192                 ; R = A+modulus
      mov      edx, 0

      mov      ecx, dword ptr[esi]     ; shifted_data = (a[0]&1)? T : A
      and      ecx, 1
      cmovnz   esi, edi
      cmovz    eax, edx
      movd     xmm0, eax
      mov      edi, pR
      CALLASM  shr_192

      mov      esp, [esp+_sp_]
      ret
IPPASM p192r1_div_by_2 ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; void p192r1_mul_mont_slm(Ipp32u* r, const Ipp32u* a, const Ipp32u* b)
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM p192r1_mul_mont_slm PROC NEAR C PUBLIC \
      USES ebp ebx esi edi,\
      pR:   PTR DWORD,\    ; product address
      pA:   PTR DWORD,\    ; source A address
      pB:   PTR DWORD     ; source B address
;
; stack layout:
;
_buf_    = 0
_rp_     = _buf_+(LEN192+1)*sizeof(dword) ; pR
_ap_     = _rp_ +sizeof(dword)            ; pA
_bp_     = _ap_+sizeof(dword)             ; pB
_sp_     = _bp_+sizeof(dword)             ; esp storage
_ssize_  = _sp_+sizeof(dword)             ; size allocated stack

      mov   eax, esp                   ; save esp
      sub   esp, _ssize_               ; allocate stack
      and   esp, -16                   ; provide 16-byte stack alignment
      mov   dword ptr[esp+_sp_], eax   ; store original esp

      ; clear buffer
      pxor  mm0, mm0
      movq  [esp+_buf_], mm0
      movq  [esp+_buf_+sizeof(qword)], mm0
      movq  [esp+_buf_+sizeof(qword)*2], mm0
      movq  [esp+_buf_+sizeof(qword)*3], mm0

      ; store parameters into the stack
      mov   edi, pR
      mov   esi, pA
      mov   ebp, pB
      mov   dword ptr[esp+_rp_], edi
      mov   dword ptr[esp+_ap_], esi
      mov   dword ptr[esp+_bp_], ebp

      mov   edi, LEN192

      movd  mm1, dword ptr[esi+sizeof(dword)]      ; pre load a[1], a[2]
      movd  mm2, dword ptr[esi+sizeof(dword)*2]


ALIGN IPP_ALIGN_FACTOR
mmul_loop:
;
; i-st pass
; modulus = 2^192 -2^64 -1
;            [6]   [2]  [0]
; m0 = 1
;
      movd     mm7, edi                   ; save pass counter

      mov      edx, dword ptr[ebp]     ; b = b[i]
      mov      eax, dword ptr[esi]     ; a[0]
      movd     mm0, edx
      add      ebp, sizeof(dword)
      mov      dword ptr[esp+_bp_], ebp

      pmuludq  mm1, mm0                   ; a[1]*b[i]

      mul      edx                        ; (E:u) = (edx:eax) = a[0]*b[i]+buf[0]
      add      eax, dword ptr[esp+_buf_]
      adc      edx, 0

      pmuludq  mm2, mm0                   ; a[2]*b[i]

; multiplication round 1 - round 2
      movd     ecx, mm1                   ; p = a[1]*b[i] + E
      psrlq    mm1, 32
      add      ecx, edx
      movd     edx, mm1
      adc      edx, 0
      add      ecx, dword ptr[esp+_buf_+sizeof(dword)*1]
      movd     mm1, dword ptr[esi+sizeof(dword)*3]
      adc      edx, 0

      movd     ebx, mm2                   ; p = a[2]*b[i] + E
      psrlq    mm2, 32
      add      ebx, edx
      movd     edx, mm2
      adc      edx, 0
      add      ebx, dword ptr[esp+_buf_+sizeof(dword)*2]
      movd     mm2, dword ptr[esi+sizeof(dword)*4]
      movd     mm3, dword ptr[esi+sizeof(dword)*5]
      adc      edx, 0

      pmuludq  mm1, mm0                   ; a[3]*b[i]
      pmuludq  mm2, mm0                   ; a[4]*b[i]
      pmuludq  mm3, mm0                   ; a[5]*b[i]

;;; and reduction ;;;
      mov      dword ptr[esp+_buf_+sizeof(dword)*0], ecx    ; +0
      sub      ebx, eax                                     ; -u0
      mov      edi, 0
      mov      dword ptr[esp+_buf_+sizeof(dword)*1], ebx
      adc      edi, 0                                       ; ssave bf

; multiplication round 3 - round 5
      movd     ecx, mm1                   ; p = a[3]*b[i] + E
      psrlq    mm1, 32
      add      ecx, edx
      movd     edx, mm1
      adc      edx, 0
      add      ecx, dword ptr[esp+_buf_+sizeof(dword)*3]
      adc      edx, 0

      movd     ebx, mm2                   ; p = a[4]*b[i] + E
      psrlq    mm2, 32
      add      ebx, edx
      movd     edx, mm2
      adc      edx, 0
      add      ebx, dword ptr[esp+_buf_+sizeof(dword)*4]
      adc      edx, 0

      movd     ebp, mm3                   ; p = a[5]*b[i] + E
      psrlq    mm3, 32
      add      ebp, edx
      movd     edx, mm3
      adc      edx, 0
      add      ebp, dword ptr[esp+_buf_+sizeof(dword)*5]
      adc      edx, 0

;;; and reduction ;;;
      sub      ecx, edi                                     ; -cb
      mov      dword ptr[esp+_buf_+sizeof(dword)*2], ecx
      sbb      ebx, 0                                       ; -bf
      mov      dword ptr[esp+_buf_+sizeof(dword)*3], ebx
      sbb      ebp, 0                                       ; -bf
      mov      dword ptr[esp+_buf_+sizeof(dword)*4], ebp

;;; last multiplication round 6
      movd     edi, mm7                   ; restore pass counter

      sbb      eax, 0                     ; u0 -bf
      mov      ebx, 0
      add      edx, dword ptr[esp+_buf_+sizeof(dword)*6]
      adc      ebx, 0
      add      edx, eax
      adc      ebx, 0
      mov      dword ptr[esp+_buf_+sizeof(dword)*5], edx
      mov      dword ptr[esp+_buf_+sizeof(dword)*6], ebx

      sub      edi, 1
      movd  mm1, dword ptr[esi+sizeof(dword)]               ; speculative load a[1], a[2], a[3], a[4]
      movd  mm2, dword ptr[esi+sizeof(dword)*2]
      jz       exit_mmul_loop

      mov      ebp, dword ptr[esp+_bp_]            ; restore pB
      jmp      mmul_loop

exit_mmul_loop:
      emms

; final reduction
      mov      edi, [esp+_rp_]         ; result
      lea      esi, [esp+_buf_]        ; buffer
      LD_ADDR  ebx, p192r1_data        ; modulus
      lea      ebx, dword ptr[ebx+(_prime192r1-p192r1_data)]
      CALLASM  sub_192
      mov      edx, dword ptr[esp+_buf_+sizeof(dword)*LEN192]
      sub      edx, eax

; copy
      cmovz    esi, edi
      cpy_192  edi, esi

      mov   esp, [esp+_sp_]            ; release stack
      ret
IPPASM p192r1_mul_mont_slm ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; void p192r1_sqr_mont_slm(Ipp32u* r, const Ipp32u* a)
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM p192r1_sqr_mont_slm PROC NEAR C PUBLIC \
      USES esi edi,\
      pR:   PTR DWORD,\    ; product address
      pA:   PTR DWORD     ; source A address

      ;; use p192r1_mul_mont_slm to compute sqr
      mov   esi, pA
      mov   edi, pR
      push  esi
      push  esi
      push  edi
      CALLASM p192r1_mul_mont_slm
      add   esp, sizeof(dword)*3
      ret
IPPASM p192r1_sqr_mont_slm ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; void p192r1_mred(Ipp32u* r, Ipp32u* prod)
;;
; modulus = 2^192  -2^64 -1
;           [6]    [2]  [0]
; m0 = 1
;
ALIGN IPP_ALIGN_FACTOR
IPPASM p192r1_mred PROC NEAR C PUBLIC \
      USES ebx esi edi,\
      pR:   PTR DWORD,\    ; reduction address
      pA:   PTR DWORD     ; source product address

   ; get parameters:
   mov   esi, pA

   mov   ecx, LEN192
   xor   edx, edx
ALIGN IPP_ALIGN_FACTOR
mred_loop:
   mov   eax, dword ptr[esi]

   mov   ebx, 0
   mov   dword ptr[esi], ebx

   mov   ebx, dword ptr[esi+sizeof(dword)]
   mov   dword ptr[esi+sizeof(dword)], ebx

   mov   ebx, dword ptr[esi+sizeof(dword)*2]
   sub   ebx, eax
   mov   dword ptr[esi+sizeof(dword)*2], ebx

   mov   ebx, dword ptr[esi+sizeof(dword)*3]
   sbb   ebx, 0
   mov   dword ptr[esi+sizeof(dword)*3], ebx

   mov   ebx, dword ptr[esi+sizeof(dword)*4]
   sbb   ebx, 0
   mov   dword ptr[esi+sizeof(dword)*4], ebx

   mov   ebx, dword ptr[esi+sizeof(dword)*5]
   sbb   ebx, 0
   mov   dword ptr[esi+sizeof(dword)*5], ebx

   mov   ebx, dword ptr[esi+sizeof(dword)*6]
   sbb   eax, 0
   add   eax, edx
   mov   edx, 0
   adc   edx, 0
   add   ebx, eax
   mov   dword ptr[esi+sizeof(dword)*6], ebx
   adc   edx, 0

   lea   esi, [esi+sizeof(dword)]
   sub   ecx, 1
   jnz   mred_loop

   ; final reduction
   mov      edi, pR           ; result
   LD_ADDR  ebx, p192r1_data  ; addres of the modulus
   lea      ebx, dword ptr[ebx+(_prime192r1-p192r1_data)]
   CALLASM  sub_192

   sub      edx, eax
   cmovz    esi, edi
   cpy_192  edi, esi

   ret
IPPASM p192r1_mred ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; void p192r1_select_pp_w5(P192_POINT *val, const P192_POINT *inTbl, int index)
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM p192r1_select_pp_w5 PROC NEAR C PUBLIC \
      USES esi edi,\
      pP:   PTR DWORD,\     ; pointer to output projective point
      pTbl: PTR DWORD,\     ; address of the table
      idx:      DWORD      ; index in the table

      pxor     xmm0, xmm0
      mov      edi, pP
      mov      esi, pTbl

      mov      eax, idx          ; broadcast input index
      movd     xmm7, eax
      pshufd   xmm7, xmm7, 00000000b

      mov      edx, 1            ; broadcast index increment index
      movd     xmm6, edx
      pshufd   xmm6, xmm6, 00000000b

      movdqa   oword ptr[edi], xmm0                   ; clear P
      movdqa   oword ptr[edi+sizeof(oword)], xmm0
      movdqa   oword ptr[edi+sizeof(oword)*2], xmm0
      movdqa   oword ptr[edi+sizeof(oword)*3], xmm0
      movq     qword ptr[edi+sizeof(oword)*4], xmm0

      ; skip index = 0, is implicictly infty -> load with offset -1
      movdqa   xmm5, xmm6           ; current_idx
      mov      ecx, 16
ALIGN IPP_ALIGN_FACTOR
select_loop:
      movdqa   xmm4, xmm5
      pcmpeqd  xmm4, xmm7     ; mask = current_idx==idx? 0xFF : 0x00

      movdqu   xmm0, oword ptr[esi]
      pand     xmm0, xmm4
      por      xmm0, oword ptr[edi]
      movdqa   oword ptr[edi], xmm0

      movdqu   xmm1, oword ptr[esi+sizeof(oword)]
      pand     xmm1, xmm4
      por      xmm1, oword ptr[edi+sizeof(oword)]
      movdqa   oword ptr[edi+sizeof(oword)], xmm1

      movdqu   xmm2, oword ptr[esi+sizeof(oword)*2]
      pand     xmm2, xmm4
      por      xmm2, oword ptr[edi+sizeof(oword)*2]
      movdqa   oword ptr[edi+sizeof(oword)*2], xmm2

      movdqu   xmm3, oword ptr[esi+sizeof(oword)*3]
      pand     xmm3, xmm4
      por      xmm3, oword ptr[edi+sizeof(oword)*3]
      movdqa   oword ptr[edi+sizeof(oword)*3], xmm3

      movq     xmm0, qword ptr[esi+sizeof(oword)*4]
      movq     xmm1, qword ptr[edi+sizeof(oword)*4]
      pand     xmm0, xmm4
      por      xmm0, xmm1
      movq     qword ptr[edi+sizeof(oword)*4], xmm0

      paddd    xmm5, xmm6     ; increment current_idx
      add      esi, sizeof(dword)*LEN192*3
      sub      ecx, 1
      jnz      select_loop

      ret
IPPASM p192r1_select_pp_w5 ENDP

ENDIF    ;; _IPP GE _IPP_P8
END
