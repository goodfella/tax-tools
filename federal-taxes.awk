BEGIN {
    tab_idx = 0;
    tol_inc = 0;
    tot_ded = 0;
    tot_exm = 0;
    tot_cre = 0;
    taxes_paid = 0;
}

# comment for tax information file just ignore the line
/\#/{}


# store tax table information
/begin-tax-table:/,/end-tax-table:/{

    if( ! match($1, /begin-tax-table:|end-tax-table:/) )
    {
	tax_tbl[tab_idx] = $0;
	++tab_idx;
    }
}


# sum up the income
/begin-income:/,/end-income:/{

    if( ! match($1, /begin-income:|end-income:/) )
    {
	tot_inc += $1;
    }
}


# sum up taxes paid
/begin-taxes-paid:/,/end-taxes-paid:/{

    if( ! match($1, /begin-taxes-paid:|end-taxes-paid:/) )
    {
	taxes_paid += $1;
    }
}


# sum up the deductions
/begin-deductions:/,/end-deductions:/{

    if( ! match($1, /begin-deductions:|end-deductions:/) )
    {
	tot_ded += $1;
    }
}


# get exemptions
/exemptions:/ { tot_exm = $2 }


# sum up the credits
/begin-credits:/,/end-credits:/{

    if( ! match($1, /begin-credits:|end-credits:/) )
    {
	tot_cre += $1;
    }
}


# print the information and calculate taxes
END {

    printf("Total income: %d\n", tot_inc);
    printf("Total deductions: %d\n", tot_ded);
    printf("Total exemptions: %d\n", tot_exm);
    printf("Total credits: %d\n", tot_cre);
    printf("Taxes paid: %d\n", taxes_paid);

    # calculate the income tax
    inc_tax = 0;

    # taxable income = income - deductions
    tax_inc = tot_inc - tot_ded

    if( tot_exm > tax_inc )
    {
	tax_inc = 0;
    }
    else
    {
	tax_inc -= tot_exm;
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
    if( tot_cre > inc_tax )
    {
	inc_tax = 0;
    }
    else
    {
	inc_tax -= tot_cre;
    }

    printf("Income tax: %d\n", inc_tax);

    printf("Refund / Payment (negative value indicates payment): %d\n",
	   taxes_paid - inc_tax);
}
