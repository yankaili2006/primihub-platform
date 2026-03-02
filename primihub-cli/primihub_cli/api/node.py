"""Node management API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class NodeAPI:
    """Node management API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize node API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def list_nodes(
        self,
        page_no: int = 1,
        page_size: int = 10,
    ) -> Dict[str, Any]:
        """
        List all nodes with pagination.

        Args:
            page_no: Page number
            page_size: Page size

        Returns:
            Node list response
        """
        response = self.client.get(
            '/node/getNodeList',
            params={
                'pageNo': page_no,
                'pageSize': page_size,
            }
        )
        return response

    def get_node(self, node_id: int) -> Dict[str, Any]:
        """
        Get node details.

        Args:
            node_id: Node ID

        Returns:
            Node details
        """
        response = self.client.get(
            '/node/getNode',
            params={'nodeId': node_id}
        )
        return response

    def get_node_status(self, node_id: int) -> Dict[str, Any]:
        """
        Get node status.

        Args:
            node_id: Node ID

        Returns:
            Node status
        """
        response = self.client.get(
            '/node/getNodeStatus',
            params={'nodeId': node_id}
        )
        return response

    def register_node(
        self,
        node_name: str,
        node_ip: str,
        node_port: int,
        organ_id: int,
    ) -> Dict[str, Any]:
        """
        Register a new node.

        Args:
            node_name: Node name
            node_ip: Node IP address
            node_port: Node port
            organ_id: Organization ID

        Returns:
            Register response
        """
        data = {
            'nodeName': node_name,
            'nodeIp': node_ip,
            'nodePort': node_port,
            'organId': organ_id,
        }

        response = self.client.post('/node/registerNode', data=data)
        return response

    def update_node(
        self,
        node_id: int,
        node_name: Optional[str] = None,
        node_ip: Optional[str] = None,
        node_port: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Update node information.

        Args:
            node_id: Node ID
            node_name: New node name
            node_ip: New node IP
            node_port: New node port

        Returns:
            Update response
        """
        data = {'nodeId': node_id}
        if node_name:
            data['nodeName'] = node_name
        if node_ip:
            data['nodeIp'] = node_ip
        if node_port:
            data['nodePort'] = node_port

        response = self.client.post('/node/updateNode', data=data)
        return response

    def delete_node(self, node_id: int) -> Dict[str, Any]:
        """
        Delete a node.

        Args:
            node_id: Node ID

        Returns:
            Delete response
        """
        response = self.client.post(
            '/node/deleteNode',
            data={'nodeId': node_id}
        )
        return response

    def connect_node(self, node_id: int, target_node_id: int) -> Dict[str, Any]:
        """
        Connect two nodes.

        Args:
            node_id: Source node ID
            target_node_id: Target node ID

        Returns:
            Connect response
        """
        data = {
            'nodeId': node_id,
            'targetNodeId': target_node_id,
        }

        response = self.client.post('/node/connectNode', data=data)
        return response

    def disconnect_node(self, node_id: int, target_node_id: int) -> Dict[str, Any]:
        """
        Disconnect two nodes.

        Args:
            node_id: Source node ID
            target_node_id: Target node ID

        Returns:
            Disconnect response
        """
        data = {
            'nodeId': node_id,
            'targetNodeId': target_node_id,
        }

        response = self.client.post('/node/disconnectNode', data=data)
        return response

    def get_node_connections(self, node_id: int) -> Dict[str, Any]:
        """
        Get node connections.

        Args:
            node_id: Node ID

        Returns:
            Node connections
        """
        response = self.client.get(
            '/node/getNodeConnections',
            params={'nodeId': node_id}
        )
        return response
