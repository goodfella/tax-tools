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

/^fed-extra-taxes:$/,/^\~fed-extra-taxes:$/{

    extra_taxes += $1;
}


# sum up the income
/^income:$/,/^\~income:$/{

    income += $1;
}


# sum up the income adjustments
/^income-adj:$/,/^\~income-adj:$/{

    inc_adj += $1;
}


# sum up the income adjustments
/^fed-income-adj:$/,/^\~fed-income-adj:$/{

	fed_inc_adj += $1;
}


# sum up taxes paid
/^fed-taxes-paid:$/,/^\~fed-taxes-paid:$/{

	taxes_paid += $1;
}


# sum up the deductions
/^fed-deductions:$/,/^\~fed-deductions:$/{

	ded += $1;
}


# get exemptions
/^fed-exemptions:$/,/^\~fed-exemptions:$/{

	exm += $1;
}

/^fed-exemption-factor:[[:space:]]*[[:digit:]]+/ {exm_factor = $2}


# sum up the credits
/^fed-credits:$/,/^\~fed-credits:$/{

	credits += $1;
}


# print the information and calculate taxes
END {

    printf("Totals:\n=======\n");
    printf("Total income: $%d\n", income);
    printf("Adjustments: $%d\n", inc_adj);
    printf("Federal adjustments: $%d\n", fed_inc_adj);
    printf("Deductions: $%d\n", ded);
    printf("Exemptions: %d\n", exm);
    printf("Exemption amount: $%d\n", exm_factor);
    printf("Credits: $%d\n", credits);
    printf("Taxes paid: $%d\n", taxes_paid);
    printf("Extra taxes: $%d\n\n", extra_taxes);

    # calculate the income tax
    inc_tax = 0;
    exm_amount = exm * exm_factor;

    # taxable income = income - deductions
    tax_inc = income - ded - inc_adj - fed_inc_adj;

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
    printf("Wages salaries, tips: $%d\n", income - inc_adj);
    printf("Adjusted gross income: $%d\n", income - inc_adj - fed_inc_adj);
    printf("Taxable income: $%d\n", tax_inc);

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

    printf("Tax: $%d\n", inc_tax);

    # credits are subtracted from income taxes
    if( credits > total_tax )
    {
	total_tax = 0;
    }
    else
    {
	total_tax -= credits;
    }

    printf("Total tax (net credits): $%d\n", total_tax);

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
    printf("Tax rates:\n==========\n")
    printf("Effective income tax rate: %.2f %% (%d / %d)\n", effective_tax_rate, total_tax, tax_inc);
    printf("Total income tax rate: %.2f %% (%d / %d)\n", tax_rate, total_tax, income);
}
