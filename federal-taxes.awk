#!/usr/bin/gawk -f

function parse_number(number)
{
    multiplier = 1;
    len = split(number, values, "x");
    if( len >= 2)
    {
	multiplier = values[2];
    }

    return (values[1] + 0.0) * int(multiplier);
}

BEGIN {tax_tbl_size = 0;}

# comment for tax information file just ignore the line
/^\#.*/{}

# store tax table information
/^fed-tax-table:$/,/^\~fed-tax-table:$/{

    if( length($0) > 0 && strtonum($1) > 0 )
    {
	tax_tbl[tax_tbl_size] = $0;
	++tax_tbl_size;
    }
}

# sum up the income
/^income:$/,/^\~income:$/{

       income += parse_number($1);
}


# sum up the income adjustments
/^income-adj:$/,/^\~income-adj:$/{

       inc_adj += parse_number($1);
}


# sum up the income adjustments
/^fed-income-adj:$/,/^\~fed-income-adj:$/{

        fed_inc_adj += parse_number($1);
}


# sum up taxes paid
/^fed-income-taxes-paid:$/,/^\~fed-income-taxes-paid:$/{

         taxes_paid += parse_number($1);
}


# sum up the deductions
/^fed-deductions:$/,/^\~fed-deductions:$/{

         ded += parse_number($1);
}

# student loan deductions
/^fed-student-loan-deductions:$/,/^\~fed-student-loan-deductions:$/ {
        student_loan_ded += parse_number($1);
	if (student_loan_ded > 2500) {
		student_loan_ded = 2500
	}
}

# get exemptions
/^fed-exemptions:$/,/^\~fed-exemptions:$/{

        exm += parse_number($1);
}

/^fed-exemption-factor:[[:space:]]*[[:digit:]]+/ {exm_factor = $2}


# sum up the credits
/^fed-credits:$/,/^\~fed-credits:$/{

        credits += parse_number($1);
}

/^fed-other-taxes-paid:$/,/^\~fed-other-taxes-paid:$/{

        fed_other_taxes_paid += parse_number($1);
}

/^fed-child-tax-credit-count:$/,/^\~fed-child-tax-credit-count:$/{
        fed_child_tax_credit_count += $1;
}

/^fed-child-tax-credit-phase-out:[[:space:]]*[[:digit:]]+/ {fed_child_tax_credit_phase_out = $2}

/^fed-child-tax-credit-amount:[[:space:]]*[[:digit:]]+/ {fed_child_tax_credit_amount = $2}

# print the information and calculate taxes
END {

    printf("Section Totals:\n===============\n");
    printf("Income: $%d\n", income);
    printf("Income adjustments: $%d\n", inc_adj);
    printf("Federal income adjustments: $%d\n", fed_inc_adj);
    printf("Federal deductions: $%d\n", ded);
    printf("Federal student loan deductions: $%d\n", student_loan_ded);
    printf("Federal exemptions: %d\n", exm);
    printf("Federal exemption factor: $%d\n", exm_factor);
    printf("Federal exemption amount: $%d\n", exm_factor * exm);
    printf("Federal credits: $%d\n", credits);
    printf("Federal child tax credit count: %d\n", fed_child_tax_credit_count);
    printf("Federal child tax credit amount: %d\n", fed_child_tax_credit_amount);
    printf("Federal child tax credit phase out: %d\n", fed_child_tax_credit_phase_out);
    printf("Federal income taxes paid: $%d\n", taxes_paid);
    printf("Federal other taxes paid: $%d\n", fed_other_taxes_paid);
    printf("Federal extra income taxes: $%d\n\n", extra_taxes);

    # calculate the income tax
    inc_tax = 0;
    exm_amount = exm * exm_factor;

    # taxable income = income - deductions
    tax_inc = income - ded - inc_adj - fed_inc_adj - student_loan_ded;

    # modified adjusted gross income
    modified_adjusted_gross_income = income - inc_adj - fed_inc_adj

    if( tax_inc < 0 )
	tax_inc = 0;

    if( exm_amount > tax_inc )
    {
	tax_inc = 0;
    }
    else
    {
	tax_inc -= exm_amount;
    }

    printf("Form 1040 calculations:\n=======================\n");
    printf("Wages salaries, tips (income - income adjustments): $%d\n",
	   income - inc_adj);
    printf("Adjusted gross income (AGI) $%d\n", income - inc_adj - fed_inc_adj - student_loan_ded);
    printf("Modified AGI: $%d\n", modified_adjusted_gross_income);
    printf("Taxable income (AGI - exemption amount - deductions): $%d\n",
	   tax_inc);

    temp_tax_inc = tax_inc;

    i = 0;
    low = 0;

    # traverse each entry in the tax table
    while( temp_tax_inc > 0 )
    {
	# split out the tax bracket information.  All brackets but the
	# last have a high salary amount and a tax percentage
	bracket = tax_tbl[i];
	bracket_idx = i;
	brac_type = split(bracket, tax_brac);

	# bracket percent is always the last element
	tax_per = strtonum(tax_brac[brac_type]);

	# the bracket has a high amount and a tax percentage
	if( brac_type == 2 )
	{
	    high = strtonum(tax_brac[1]);

	    bracket_range = high - low;

	    bracket_income = bracket_range < temp_tax_inc ? bracket_range : temp_tax_inc;
	    remaining = bracket_range - bracket_income;
	}
	# the bracket has only a tax percentage
	else if ( brac_type == 1 )
	{
	    bracket_income = temp_tax_inc;
	    remaining = 0;
	}

	bracket_tax = bracket_income * tax_per;
	inc_tax += bracket_tax;
	bracket_taxes[bracket_idx] = sprintf("bracket income: $%d, tax rate: %d %%, low: %d, high: %d, remaining: %d, taxes: $%.2f",
					     bracket_income, tax_per * 100, low, high, remaining, bracket_tax);

	temp_tax_inc -= bracket_income;
	++i;

	# the current bracket high becomes the next bracket's low
	low = high;
    }

    # round up
    inc_tax += .5;
    total_tax = inc_tax + extra_taxes;

    child_tax_credit = fed_child_tax_credit_count * fed_child_tax_credit_amount;
    if (modified_adjusted_gross_income > fed_child_tax_credit_phase_out) {
	    child_tax_credit -= ((modified_adjusted_gross_income - fed_child_tax_credit_phase_out) / 1000) * 50
    }

    credits += child_tax_credit;

    printf("Income tax: $%d\n", inc_tax);
    printf("Credits: $%d\n", credits);
    printf("Child tax credits: $%d\n", child_tax_credit)

    # credits are subtracted from income taxes
    if( credits > total_tax )
    {
	total_tax = 0;
    }
    else
    {
	total_tax -= credits;
    }

    printf("Total tax (income tax - credits): $%d\n", total_tax);

    res = taxes_paid - total_tax;

    if( res < 0 )
    {
	printf("Payment: $%d\n", -1 * res);
    }
    else if( res > 0 )
    {
	printf("Refund: $%d\n", res);
    }

    effective_tax_rate = total_tax / tax_inc * 100;
    tax_rate = total_tax / income * 100;

    print ""
    printf("Bracket breakdown:\n==================\n");
    for(bracket in bracket_taxes)
    {
	print bracket_taxes[bracket];
    }

    print ""
    printf("Effective income tax rates:\n===========================\n")
    printf("income tax / taxable income: %.2f %% (%d / %d)\n", effective_tax_rate, total_tax, tax_inc);
    printf("income tax / total income: %.2f %% (%d / %d)\n", tax_rate, total_tax, income);

    print ""
    printf("Effective other tax rates:\n==========================\n")
    printf("other tax / taxable income: %.2f %% (%d / %d)\n",
	   fed_other_taxes_paid / tax_inc * 100, fed_other_taxes_paid, tax_inc);
    printf("other tax / total income: %.2f %% (%d / %d)\n",
	   fed_other_taxes_paid / income * 100, fed_other_taxes_paid, income);
}
