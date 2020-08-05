## Non-Domestic Lodgment Rules

###### Must not be more than 4 years ago:
`"Inspection-Date", "Registration-Date" and "Issue-Date"`

###### Must not be in the future:
```"Inspection-Date", "Registration-Date", "Issue-Date", "Effective-Date", "OR-Availability-Date", "Start-Date" and "OR-Assessment-Start-Date"```

###### Must be greater than 0:
`"Floor-Area"`

###### Must NOT be equal to -1:
`"SER", "BER", "TER" and "TYR" `

###### Must NOT be equal to 7:
`"Transaction-Type", "Reason-Type" `

###### Must NOT be equal to 13:
`"EPC-Related-Party-Disclosure"`

###### Must not be equal to 4:
`"Energy-Type"`

###### Must not be equal to 8:
`"DEC-Related-Party-Disclosure"`

###### If "Question-Code" is supplied then "Question-Code-Number" must be supplied
`"Question-Code", "Question-Code-Number"`

###### If "Answer-Code" is supplied then "Answer-Code-Number" must be supplied
`"Answer-Code", "Answer-Code-Number"`

###### "Nominated-Date" must not be more than three months after "OR-Assessment-End-Date"
`Nominated-Date", "OR-Assessment-End-Date"`

###### "If "AC-Present" is equal to "Yes" then: if "AC-Rating-Unknown-Flag" is equal to "true" then "AC-Estimated-Output" must be provided, if "AC-Rated-Output" is greater than 12 then "AC-Estimated-Output" must be provided, if "AC-Estimated-Output" is equal to 2 or 3 then "AC-Inspection-Commissioned" must not be equal to 4"

```"AC-Present", "AC-Rating-Unknown-Flag", "AC-Estimated-Output", "AC-Rated-Output", "AC-Estimated-Output", "AC-Estimated-Output", "AC-Inspection-Commissioned" ```
