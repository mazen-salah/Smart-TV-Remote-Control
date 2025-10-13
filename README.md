# 📱 Smart TV Remote Control

This app allows you to control your Smart TV from your mobile device. Connect seamlessly and enjoy the convenience of controlling your TV without the need for a physical remote.

## Features

- **Device Discovery**: Automatically finds your Samsung Smart TV on the same network.
- **Remote Control**: Navigate, select, and control your TV with your mobile device.
- **User-Friendly Interface**: Easy to use interface that mimics your TV remote.

## Getting Started

To get started, simply download the app and ensure your mobile device is connected to the same Wi-Fi network as your Samsung Smart TV. Open the app, and it will automatically search for available devices. Select your TV from the list, and you will be taken to the remote control screen.

### 1. Device Discovery

```mermaid
flowchart TD
    A[User opens app] --> B[DeviceSelectionScreen]
    B --> C[Starts UPnP Discovery]
    C --> D[Searches for Samsung devices]
    D --> E{Devices found?}
    E --|Yes| F[Shows TV list]
    E --|No| G[Shows "Not found" message]
    F --> H[User selects TV]
    H --> I[Connects to device]
    I --> J[Navigates to RemoteScreen]
```

### 2. Remote Control

Once connected, you can use your mobile device as a remote control. The remote control interface includes all the essential buttons like power, volume, channel navigation, and directional pad. 

### 3. Troubleshooting

- **TV Not Found**: Ensure that your TV is turned on and connected to the same Wi-Fi network as your mobile device.
- **Connection Issues**: Restart the app and try to reconnect. If the problem persists, restart your TV and mobile device.

## Contributing

We welcome contributions to improve the app. Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make the necessary changes and commit them.
4. Push your changes to your forked repository.
5. Submit a pull request detailing your changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
