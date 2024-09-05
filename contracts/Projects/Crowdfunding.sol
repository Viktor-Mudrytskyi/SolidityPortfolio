// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Crowdfunding is ReentrancyGuard {
    struct Contributor {
        address contributor;
        uint256 amount;
    }

    struct Project {
        bytes32 uid;
        address creator;
        string projectName;
        string projectDescription;
        uint256 projectFundingGoal;
        ProjectStatus projectStatus;
    }

    enum ProjectStatus {
        Active,
        Succeeded
    }

    event ProjectCreated(bytes32 indexed projectId, address indexed creator);
    event ProjectFunded(
        bytes32 indexed projectId,
        address indexed contributor,
        uint256 indexed amount
    );
    event ContributorRefunded(
        bytes32 indexed projectId,
        address indexed contributor,
        uint256 indexed amount
    );

    error CreationInvalidData();
    error ProjectAlreadyExists(bytes32 uid);
    error ProjectDoesntExist(bytes32 uid);
    error ProjectIsNotActive(bytes32 uid);
    error TransferFailed(address sender);

    Project[] public allProjects;
    mapping(bytes32 => Project) public allProjectsMap;
    mapping(bytes32 => mapping(address => uint256)) public contributorsMap;
    mapping(bytes32 => uint256) public fundingMap;

    function createProject(
        string calldata _name,
        string calldata _description,
        uint256 _fundingGoal
    ) external returns (bytes32 projectId) {
        if (
            bytes(_name).length == 0 ||
            bytes(_description).length == 0 ||
            _fundingGoal == 0
        ) {
            revert CreationInvalidData();
        }

        projectId = _createUid(_name, _description, _fundingGoal);

        if (exists(projectId)) {
            revert ProjectAlreadyExists(projectId);
        }

        Project memory project = Project(
            projectId,
            msg.sender,
            _name,
            _description,
            _fundingGoal,
            ProjectStatus.Active
        );

        allProjectsMap[projectId] = project;
        allProjects.push(project);

        emit ProjectCreated(projectId, msg.sender);
    }

    function contribute(bytes32 _projectId) external payable nonReentrant {
        if (!exists(_projectId)) {
            revert ProjectDoesntExist(_projectId);
        }

        Project memory project = allProjectsMap[_projectId];

        unchecked {
            int256 sendValue = int256(msg.value);
            int256 projectCurrent = int256(fundingMap[_projectId]);
            int256 excessAmount = int256(
                projectCurrent + sendValue - int256(project.projectFundingGoal)
            );
            if (excessAmount > 0) {
                sendValue = sendValue - excessAmount;
                (bool success, ) = msg.sender.call{
                    value: uint256(excessAmount)
                }("");
                if (!success) {
                    revert TransferFailed(msg.sender);
                }
            }

            contributorsMap[_projectId][msg.sender] += uint256(sendValue);
            fundingMap[_projectId] += uint256(sendValue);

            emit ProjectFunded(_projectId, msg.sender, uint256(sendValue));
        }
    }

    function refund(bytes32 _projectId) external {
        _refund(msg.sender, _projectId);
    }

    function exists(bytes32 _uid) public view returns (bool) {
        return allProjectsMap[_uid].creator != address(0);
    }

    // Internal

    function _refund(
        address _sender,
        bytes32 _projectId
    ) internal nonReentrant {
        if (!exists(_projectId)) {
            revert ProjectDoesntExist(_projectId);
        }

        uint256 amount = contributorsMap[_projectId][_sender];

        (bool success, ) = _sender.call{value: amount}("");
        if (!success) {
            revert TransferFailed(_sender);
        }
        delete contributorsMap[_projectId][_sender];
        fundingMap[_projectId] -= amount;

        emit ContributorRefunded(_projectId, _sender, amount);
    }

    function _createUid(
        string calldata _name,
        string calldata _description,
        uint256 _fundingGoal
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_name, _description, _fundingGoal));
    }

    // Getters

    function getAllProjects() public view returns (Project[] memory) {
        return allProjects;
    }
}

// 1725642134 - timestamp
