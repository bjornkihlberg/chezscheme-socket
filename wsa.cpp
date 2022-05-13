// https://www.binarytides.com/winsock-socket-programming-tutorial/
#include <winsock2.h>

#pragma comment(lib, "Ws2_32.lib")

// gcc -shared -o wsa.dll wsa.cpp -lWs2_32

extern "C" {
    __declspec(dllexport)
    int socketBind(int port, SOCKET* ptr) {
        WSADATA wsaData;
        SOCKET s;
        struct sockaddr_in server;

        if (WSAStartup(MAKEWORD(2,2), &wsaData) != 0)
            return WSAGetLastError();

        if((s = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
            return WSAGetLastError();

        server.sin_addr.s_addr = INADDR_ANY;
        server.sin_family = AF_INET;
	    server.sin_port = htons(port);
        if (bind(s, (struct sockaddr *)&server, sizeof(server)) == SOCKET_ERROR)
            return WSAGetLastError();

        *ptr = s;
        return 0;
    }

    __declspec(dllexport)
    int socketListen(SOCKET s, int backLog) {
        if (listen(s, backLog) == SOCKET_ERROR)
            return WSAGetLastError();
        return 0;
    }

    __declspec(dllexport)
    int socketAccept(SOCKET s, SOCKET* ptr) {
        struct sockaddr_in client;
        int c = sizeof(struct sockaddr_in);
        SOCKET new_socket = accept(s, (struct sockaddr *)&client, &c);
        if (new_socket == INVALID_SOCKET)
            return WSAGetLastError();
        *ptr = new_socket;
        return 0;
    }

    __declspec(dllexport)
    int socketConnect(const char* serverAddress, int port, SOCKET* ptr) {
        WSADATA wsaData;
        SOCKET s;
        struct sockaddr_in server;

        if (WSAStartup(MAKEWORD(2,2), &wsaData) != 0)
            return WSAGetLastError();

        if((s = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
            return WSAGetLastError();

        server.sin_addr.s_addr = inet_addr(serverAddress);
        server.sin_family = AF_INET;
	    server.sin_port = htons(port);
        if (connect(s , (struct sockaddr*)&server , sizeof(server)) < 0)
            return WSAGetLastError();

        *ptr = s;
        return 0;
    }

    __declspec(dllexport)
    int socketSend(SOCKET s, const char* message) {
        if (send(s, message, strlen(message), 0) < 0)
            return WSAGetLastError();
        return 0;
    }

    __declspec(dllexport)
    int socketReceive(SOCKET s, char* reply, int len, int* recv_size) {
        if ((*recv_size = recv(s, reply, len, 0)) == SOCKET_ERROR)
            return WSAGetLastError();
        return 0;
    }

    __declspec(dllexport)
    int socketClose(SOCKET s) {
        if (closesocket(s) == SOCKET_ERROR)
            return WSAGetLastError();
        return 0;
    }

    __declspec(dllexport)
    int socketCleanup() {
        if (WSACleanup() == SOCKET_ERROR)
            return WSAGetLastError();
        return 0;
    }
}
