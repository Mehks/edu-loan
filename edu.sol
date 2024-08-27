// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EducationalLoanPlatform {

    struct Loan {
        address lender;
        address borrower;
        address educationalInstitution;
        uint256 amount;
        uint256 interestRate; // Interest rate in basis points (1/100th of a percent)
        uint256 duration; // Duration in seconds
        uint256 startTime;
        bool repaid;
    }

    mapping(uint256 => Loan) public loans;
    mapping(address => uint256[]) public borrowerLoans;
    mapping(address => uint256[]) public lenderLoans;
    mapping(address => uint256[]) public institutionLoans;

    uint256 public loanCounter;

    event LoanCreated(uint256 loanId, address indexed lender, address indexed borrower, address indexed institution, uint256 amount, uint256 interestRate, uint256 duration);
    event LoanRepaid(uint256 loanId, address indexed borrower);
    event LoanDefaulted(uint256 loanId, address indexed borrower);

    modifier onlyBorrower(uint256 _loanId) {
        require(msg.sender == loans[_loanId].borrower, "Not the borrower");
        _;
    }

    modifier onlyLender(uint256 _loanId) {
        require(msg.sender == loans[_loanId].lender, "Not the lender");
        _;
    }

    modifier onlyInstitution(uint256 _loanId) {
        require(msg.sender == loans[_loanId].educationalInstitution, "Not the educational institution");
        _;
    }

    function createLoan(address _borrower, address _educationalInstitution, uint256 _amount, uint256 _interestRate, uint256 _duration) external payable {
        require(msg.value == _amount, "Incorrect amount sent");
        require(_borrower != address(0), "Invalid borrower address");
        require(_educationalInstitution != address(0), "Invalid educational institution address");
        require(_interestRate > 0, "Interest rate must be positive");
        require(_duration > 0, "Duration must be positive");

        loanCounter++;
        loans[loanCounter] = Loan({
            lender: msg.sender,
            borrower: _borrower,
            educationalInstitution: _educationalInstitution,
            amount: _amount,
            interestRate: _interestRate,
            duration: _duration,
            startTime: block.timestamp,
            repaid: false
        });

        lenderLoans[msg.sender].push(loanCounter);
        borrowerLoans[_borrower].push(loanCounter);
        institutionLoans[_educationalInstitution].push(loanCounter);

        emit LoanCreated(loanCounter, msg.sender, _borrower, _educationalInstitution, _amount, _interestRate, _duration);
    }

    function repayLoan(uint256 _loanId) external payable onlyBorrower(_loanId) {
        Loan storage loan = loans[_loanId];
        require(!loan.repaid, "Loan already repaid");
        require(block.timestamp <= loan.startTime + loan.duration, "Loan duration has passed");

        uint256 amountOwed = loan.amount + (loan.amount * loan.interestRate / 10000);
        require(msg.value == amountOwed, "Incorrect repayment amount");

        loan.repaid = true;
        payable(loan.lender).transfer(msg.value);

        emit LoanRepaid(_loanId, msg.sender);
    }

    function checkDefault(uint256 _loanId) external onlyLender(_loanId) {
        Loan storage loan = loans[_loanId];
        require(!loan.repaid, "Loan already repaid");
        require(block.timestamp > loan.startTime + loan.duration, "Loan duration has not passed");

        loan.repaid = true; // Mark as repaid for this case
        emit LoanDefaulted(_loanId, loan.borrower);
    }

    function getLoan(uint256 _loanId) external view returns (Loan memory) {
        return loans[_loanId];
    }

    function getBorrowerLoans(address _borrower) external view returns (uint256[] memory) {
        return borrowerLoans[_borrower];
    }

    function getLenderLoans(address _lender) external view returns (uint256[] memory) {
        return lenderLoans[_lender];
    }

    function getInstitutionLoans(address _institution) external view returns (uint256[] memory) {
        return institutionLoans[_institution];
    }
}
