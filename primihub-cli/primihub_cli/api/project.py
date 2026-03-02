"""Project management API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class ProjectAPI:
    """Project management API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize project API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def list_projects(self, page_no: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """
        List projects with pagination.

        Args:
            page_no: Page number
            page_size: Page size

        Returns:
            Project list response
        """
        response = self.client.get(
            '/project/getProjectList',
            params={
                'pageNo': page_no,
                'pageSize': page_size,
            }
        )
        return response

    def get_project(self, project_id: int) -> Dict[str, Any]:
        """
        Get project details.

        Args:
            project_id: Project ID

        Returns:
            Project details
        """
        response = self.client.get(
            '/project/getProjectDetails',
            params={'projectId': project_id}
        )
        return response

    def create_project(
        self,
        project_name: str,
        project_desc: Optional[str] = None,
        project_type: int = 0,
    ) -> Dict[str, Any]:
        """
        Create a new project.

        Args:
            project_name: Project name
            project_desc: Project description
            project_type: Project type (0=PSI, 1=PIR, 2=FL)

        Returns:
            Create project response
        """
        data = {
            'projectName': project_name,
            'projectType': project_type,
        }
        if project_desc:
            data['projectDesc'] = project_desc

        response = self.client.post('/project/saveProject', data=data)
        return response

    def update_project(
        self,
        project_id: int,
        project_name: Optional[str] = None,
        project_desc: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Update project information.

        Args:
            project_id: Project ID
            project_name: New project name
            project_desc: New project description

        Returns:
            Update response
        """
        data = {'projectId': project_id}
        if project_name:
            data['projectName'] = project_name
        if project_desc:
            data['projectDesc'] = project_desc

        response = self.client.post('/project/updateProject', data=data)
        return response

    def delete_project(self, project_id: int) -> Dict[str, Any]:
        """
        Delete a project.

        Args:
            project_id: Project ID

        Returns:
            Delete response
        """
        response = self.client.post(
            '/project/deleteProject',
            data={'projectId': project_id}
        )
        return response
