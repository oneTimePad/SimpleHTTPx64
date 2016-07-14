

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
  sub rsp, 4  ;char[4]
  xor rax,rax
  mov rax,0x0a4b4b4b
  xor rbx,rbx
  mov rbx,rdi
  xor rdi,rdi
  lea rdi,[rsp]
  stosd
  xor rsi,rsi  ;write 4 bytes
  lea rsi, [rsp]
  push BYTE 0x1
  pop rax
  push BYTE 0x4
  pop rdx
  mov rdi,rbx
  syscall
  push BYTE 0x3
  pop rax
  syscall
  add rsp ,4
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

  ;setsocketopt(fd,SOL_SOCKET,SO_REUSEADDR,&socklen_t,socklen_t)
  ;push BYTE 54
  ;pop rax        ;syscall 54
  ;push BYTE 2
  ;pop rdx        ;size of SO_REUSEADDR
  ;sub rsp,4
  ;push QWORD rsp
  ;pop r10        ;&socklen_t
  ;push BYTE 4
  ;pop r8         ;size socklen_t
  ;syscall
  ;cmp rax,0
  ;jl fail


  ;bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
  xor rax,rax
  mov al,49       ;syscall 49

  ;build sockaddr_in
  push 0x2
  mov word [rsp+2],0x6aea
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

  ;sub rsp,2
  ;lea rsi, [rsp]
  ;xor rdx,rdx
  ;mov rdx, 0x10
  ;accept and fork

  main_accept_loop:
    ;accept(sockfd,(struct sockaddr*)&client,sockaddr_len)
    xor rsi,rsi
    xor rdx,rdx
    mov rax,0x2b
    syscall
    cmp rax,-1
    jl fail
    ;fork()
    xor rdi,rdi
    mov rdi,rax
    push BYTE 57
    pop rax
    syscall
    test rax,rax
    jz child
    jmp main_accept_loop
    child:
      call socket_handler
      push BYTE 60
      pop rax
      xor rdi,rdi
      syscall
