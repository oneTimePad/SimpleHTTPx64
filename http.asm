

section .data
  http:  db "HTTP/1.1 200 OK", 0x0a, "Connection: close",0x0a,"Content-Type: text/html",0x0a,"Content-Length: 143",0x0a,0x0a,0
  index: db "<html><body><b>I'm written in assembly!</b>",0x0
  index2: db "<form><label for='text'>Write something!</label><input id='text' type='text'/></form></body></html>",0

global main
section .text

extern socket

fail:
  mov rax,60
  mov rdi,1
  syscall

socket_handler:
  push rbp
  mov rbp,rsp
  push rbx
  ;write 4 bytes to socket
  sub rsp, 0xde  ;char[4]
  xor rdx,rdx
  mov rdx, 0xde
  xor rbx,rbx
  mov rbx,rdi
  xor rsi,rsi  ;write 4 bytes
  lea rsi, [http]
  xor rdi,rdi
  mov rdi,rsp
  xor rcx,rcx
  mov cl,0x4f
  rep movsb
  mov cl,0x2c
  lea rsi, [index]
  rep movsb
  mov cl,0x63
  lea rsi, [index2]
  rep movsb
  push BYTE 0x1
  pop rax
  mov BYTE [rdi],0
  mov rdi,rbx
  mov rsi,rsp
  syscall

  xor rax,rax
  lea rsi,[rsp+0x4f]
  syscall
  mov BYTE [rsp+0x50+rax],0x0
  xor rbx,rbx
  mov rbx,rax
  syscall

  xor rsi,rsi
  xor rdx,rdx
  push BYTE 0x3
  pop rax
  syscall
  add rsp ,0xde
  pop rbx
  mov rsp,rbp
  pop rbp
  ret






main:
  push rbp
  mov rbp,rsp

 ; s =socket(AF_INET,SOCK_STREAM,IPPROTO_IP)
  mov dil,2  ;AF_INET
  xor rsi,rsi
  mov sil,1  ;SOCK_STREAM
  xor rdx,rdx ;IPPROTO_IP
  xor rax, rax
  mov al,41  ;syscall 41
  syscall
  cmp rax,0
  jl fail

  mov rdi,rax   ;sockfd

;  setsocketopt(fd,SOL_SOCKET,SO_REUSEADDR,&socklen_t,socklen_t)
  push BYTE 54
  pop rax        ;syscall 54
  push BYTE 2
  pop rdx        ;size of SO_REUSEADDR
  sub rsp,4
  push QWORD rsp
  pop r10        ;&socklen_t
  push BYTE 4
  pop r8         ;size socklen_t
  syscall
  cmp rax,0
  jl fail


  ;bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
  xor rax,rax
  mov al,49       ;syscall 49

  ;build sockaddr_in
  push 0x2
  mov word [rsp+2],0x79ea
  mov rsi,rsp

  mov rdx, 16
  syscall
  cmp rax, -1
  jl fail

  ;listen(sockfd,8)
  pop rsi
  mov rax,0x32
  syscall
  cmp rax,-1
  jl fail

  ;accept and fork

  main_accept_loop:
    ;accept(sockfd,(struct sockaddr*)&client,sockaddr_len)
    xor rsi,rsi
    xor rdx,rdx
    xor rax,rax
    mov rax,0x2b
    syscall
    cmp rax,-1
    jl fail
    ;fork()
    xor rbx,rbx
    mov rbx,rax
    push BYTE 57
    pop rax
    syscall
    test rax,rax
    jz child
    jmp main_accept_loop
    child:
      xor rdi,rdi
      mov rdi,rbx
      call socket_handler
      push BYTE 60
      pop rax
      xor rdi,rdi
      syscall
