BEGIN {
    tab_idx = 0;
    income = 0;
    inc_adj = 0;
    fed_inc_adj = 0;
    ded = 0;
    exm = 0;
    credits = 0;
    taxes_paid = 0;
}

# comment for tax information file just ignore the line
/^\#/{}


# store tax table information
/^fed-tax-table:$/,/^\~fed-tax-table:$/{

    if( ! match($1, /^fed-tax-table:$|^\~fed-tax-table:$/) )
    {
	tax_tbl[tab_idx] = $0;
	++tab_idx;
    }
}


# sum up the income
/^income:$/,/^\~income:$/{

    if( ! match($1, /^income:$|^\~income:$/) )
    {
	income += $1;
    }
}


# sum up the income adjustments
/^income-adj:$/,/^\~income-adj:$/{

    if( ! match($1, /^income-adj:$|^\~income-adj:$/) )
    {
	inc_adj += $1;
    }
}


# sum up the income adjustments
/^fed-income-adj:$/,/^\~fed-income-adj:$/{

    if( ! match($1, /^fed-income-adj:$|^\~fed-income-adj:$/) )
    {
	fed_inc_adj += $1;
    }
}


# sum up taxes paid
/^fed-taxes-paid:$/,/^\~fed-taxes-paid:$/{

    if( ! match($1, /^fed-taxes-paid:$|^\~fed-taxes-paid:$/) )
    {
	taxes_paid += $1;
    }
}


# sum up the deductions
/^fed-deductions:$/,/^\~fed-deductions:$/{

    if( ! match($1, /^fed-deductions:$|^\~fed-deductions:$/) )
    {
	ded += $1;
    }
}


# get exemptions
/fed-exemptions:/ { exm = $2 }


# sum up the credits
/^fed-credits:$/,/^\~-fed-credits:$/{

    if( ! match($1, /^fed-credits:$|^\~fed-credits:$/) )
    {
	credits += $1;
    }
}


# print the information and calculate taxes
END {

    printf("Total income: %d\n", income);
    printf("Adjustments: %d\n", inc_adj + fed_inc_adj);
    printf("Deductions: %d\n", ded);
    printf("Exemptions: %d\n", exm);
    printf("Credits: %d\n", credits);
    printf("Taxes paid: %d\n", taxes_paid);

    # calculate the income tax
    inc_tax = 0;

    # taxable income = income - deductions
    tax_inc = income - ded - inc_adj - fed_inc_adj;

    if( tax_inc < 0 )
	tax_inc = 0;

    if( exm > tax_inc )
    {
	tax_inc = 0;
    }
    else
    {
	tax_inc -= exm;
    }

    printf("Taxable income: %d\n", tax_inc);

    # traverse each entry in the tax table
    for( i = 0; i < tab_idx; ++i)
    {
	# split out the tax bracket information.  All brackets but the
	# last have a low and high salary amount.
	brac_type = split(tax_tbl[i], tax_brac);

	low = strtonum(tax_brac[1]);

	# the bracket has a low and high amount
	if( brac_type == 3 )
	{
	    high = strtonum(tax_brac[2]);
	    per = strtonum(tax_brac[3]);

	    if( tax_inc < high )
	    {
		inc_tax += (tax_inc - low) * per;
		break;
	    }

	    inc_tax += (high - low) * per;
	}
	# the bracket has only a low amount
	else if ( brac_type == 2 )
	{
	    per = tax_brac[2];

	    if( tax_inc > low )
	    {
		inc_tax += (tax_inc - low) * per;
		break;
	    }
	}
    }

    # credits are subtracted from income taxes
    if( credits > inc_tax )
    {
	inc_tax = 0;
    }
    else
    {
	inc_tax -= credits;
    }

    printf("Total tax: %d\n", inc_tax);
    printf("Effective tax rate: %f\n", inc_tax / income * 100);

    res = taxes_paid - inc_tax;

    if( res < 0 )
    {
	printf("Payment: %d\n", -1 * res);
    }
    else if( res > 0 )
    {
	printf("Refund: %d\n", res);
    }
}
