# Template for XML profiles for WSDL files
,
{
    "attachmentsInSoapMessages" : false,
    "attackSignaturesCheck" : true,
    "defenseAttributes" : {
        "allowCDATA" : false,
        "allowDTDs" : false,
        "allowExternalReferences" : false,
        "allowProcessingInstructions" : false,
        "maximumAttributeValueLength" : {{VAR_XML_ATTRIBUTE_VALUE_LENGTH}},
        "maximumAttributesPerElement" : {{VAR_XML_MAX_ATTRIBUTES_PER_ELEMENT}},
        "maximumChildrenPerElement" : {{VAR_XML_MAX_CHILDREN_PER_ELEMENT}},
        "maximumDocumentDepth" : {{VAR_XML_MAX_DOCUMENT_DEPTH}},
        "maximumDocumentSize" : {{VAR_XML_MAX_DOCUMENT_SIZE}},
        "maximumElements" : {{VAR_XML_MAX_ELEMENTS}},
        "maximumNSDeclarations" : {{VAR_XML_MAX_NS_DECLARATIONS}},
        "maximumNameLength" : {{VAR_XML_MAX_NAME_LENGTH}},
        "maximumNamespaceLength" : {{VAR_XML_MAX_NAMESPACE_LENGTH}},
        "tolerateCloseTagShorthand" : true,
        "tolerateLeadingWhiteSpace" : true,
        "tolerateNumericNames" : true
    },
    "description" : "",
    "enableWss" : false,
    "followSchemaLinks" : false,
    "inspectSoapAttachments" : false,
    "metacharAttributeCheck" : {{VAR_XML_METACHAR_ATTRIBUTE_CHECK}},
    "metacharElementCheck" : {{VAR_XML_METACHAR_ELEMENT_CHECK}},
    "name" : "{{XML_PROFILE_NAME}}",
    "useXmlResponsePage" : true,
    "validationFiles" : [
        {
            "isPrimary" : true,
            "xmlValidationFile" : {
                "fileName" : "{{XML_PROFILE_FILENAME}}"
            }
        }
        {{GET_XMLPROFILE_IMPORTS}}
    ],
    "validationSoapActionHeader" : true,
    "sensitiveData": [
        { "namespace": "*", "paramName": "wsc:SecurityContextToken", "paramType": "Element" }
    ]
}
