// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { ERC721Facet } from "./ERC721Facet.sol";
import { IERC721 } from "../libraries/IERC721.sol";
import {IERC20} from "../libraries/IERC20.sol";


contract NFTLendFacet is ERC721Facet {

    address public loanTokenAddress;

    event LoanTaken(address indexed borrower, uint256 loanAmount, address nftAddress, uint256 nftTokenId);
    event LoanRepaid(address indexed borrower, uint256 loanAmount, address nftAddress, uint256 nftTokenId);

    constructor(address _loanTokenAddress) {
        loanTokenAddress = _loanTokenAddress;
    }

    function takeLoan(address nftAddress, uint256 nftTokenId, uint256 loanAmount) external {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        require(IERC721(nftAddress).ownerOf(nftTokenId) == msg.sender, "You do not own this NFT");
        require(IERC20(loanTokenAddress).balanceOf(address(this)) >= loanAmount, "Insufficient funds");
        IERC721(nftAddress).transferFrom(msg.sender, address(this), nftTokenId);


        ds.loans[msg.sender] = LibDiamondStorage.Loan({
            loanAmount: loanAmount,
            nftAddress: nftAddress,
            nftTokenId: nftTokenId,
            isActive: true
        });

        require(IERC20(loanTokenAddress).transfer(msg.sender, loanAmount), "Transfer Failed");

        emit LoanTaken(msg.sender, loanAmount, nftAddress, nftTokenId);
    }

    function repayLoan() external payable {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        LibDiamondStorage.Loan storage loan = ds.loans[msg.sender];

        require(loan.isActive, "No active loan found");

        require(IERC20(loanTokenAddress).transferFrom(msg.sender, address(this), loan.loanAmount), "Repayment failed");

        loan.isActive = false;

        IERC721(loan.nftAddress).transferFrom(address(this), msg.sender, loan.nftTokenId);

        emit LoanRepaid(msg.sender, loan.loanAmount, loan.nftAddress, loan.nftTokenId);
    }
}