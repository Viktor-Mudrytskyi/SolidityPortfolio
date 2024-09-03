// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Crowdfunding {
    struct Project {
        uint256 uid;
        address creator;
        string name;
        string description;
        uint256 deadline;
        ProjectStatus status;
        Action action;
    }

    struct Action {
        address to;
        string func;
        bytes data;
    }

    enum ProjectStatus {
        Active,
        Succeeded,
        Defeated
    }

    event ProjectCreated(Project indexed project, address indexed creator);

    error DeadlinePassed(uint256 deadline);
    error InvalidData();

    Project[] public projects;
    mapping(uint256 => Project) public projectMap;

    //////////////////////////

    string public demoString;
    function demo(string memory data) external {
        demoString = data;
    }

    function getBytes(string memory data) external pure returns (bytes memory) {
        return bytes(data);
    }

    ///////////////////////////

    function createProject(
        string calldata _name,
        string calldata _description,
        uint256 _deadline,
        address _to,
        string calldata _func,
        bytes calldata _data
    ) public returns (Project memory) {
        if (_deadline <= block.timestamp) {
            revert DeadlinePassed(_deadline);
        }
        if (bytes(_name).length == 0 || bytes(_description).length == 0) {}
        uint256 uid = projects.length;
        Project memory newProject = Project({
            uid: uid,
            name: _name,
            creator: msg.sender,
            description: _description,
            deadline: _deadline,
            status: ProjectStatus.Active,
            action: Action({to: _to, func: _func, data: _data})
        });
        projectMap[uid] = newProject;
        projects.push(newProject);
        return newProject;
    }

    function getProject(uint256 uid) public view returns (Project memory) {
        return projectMap[uid];
    }
}

/////////////
// 1725399784 timestamp
// demo(string)

// 0x74657374
