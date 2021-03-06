(* Wolfram Language Package *)

BeginPackage["BayesianVisualisations`", { "BayesianUtilities`"}]
(* Exported symbols added here with SymbolName::usage *)  
covarianceMatrixPlot;
posteriorMarginalPDFPlot1D;
posteriorMarginalPDFDensityPlot2D;
posteriorBubbleChart;
gaussianProcessPredictionPlot;


Begin["`Private`"] (* Begin Private Context *) 

covarianceMatrixPlot[result_?(AssociationQ[#] && KeyExistsQ[#, "EmpiricalPosteriorDistribution"]&), opts : OptionsPattern[]] :=
    MatrixPlot[
        Covariance[result["EmpiricalPosteriorDistribution"]],
        Sequence @@ FilterRules[{opts}, Options[MatrixPlot]],
        PlotLegends -> Automatic,
        FrameTicks -> ConstantArray[
            Transpose[{Range[Length[result["Parameters"]]], result["Parameters"]}],
            {2, 2}
        ]
    ];

Options[covarianceMatrixPlot] = Join[
    {},
    Options[MatrixPlot]
];

posteriorMarginalPDFPlot1D[result_?AssociationQ, parameter_Symbol, opts : OptionsPattern[]] /; MemberQ[result["Parameters"], parameter] :=
    posteriorMarginalPDFPlot1D[result, First @ FirstPosition[result["Parameters"], parameter, Missing["Error"], {1}], opts];

posteriorMarginalPDFPlot1D[result_?AssociationQ, plotIndex_Integer, range : (Automatic | {_, _}) : Automatic, opts : OptionsPattern[]] /;
    (AllTrue[{"ParameterRanges", "EmpiricalPosteriorDistribution"}, KeyExistsQ[result, #]&] && plotIndex <= Length[result["ParameterRanges"]]) :=
    Module[{
        x, pdf,
        plotRange = Replace[range, Automatic :> result["ParameterRanges"][[plotIndex]]]
    },
        pdf = PDF[
            SmoothKernelDistribution[
                WeightedData @@ Map[
                    MarginalDistribution[
                        result["EmpiricalPosteriorDistribution"],
                        plotIndex
                    ],
                    {"Domain", "Weights"}
                ],
                Sequence @@ OptionValue["SmoothKernelDistributionOptions"]
            ],
            x
        ];
        Plot[
            pdf,
            Evaluate[Flatten @ {x, plotRange}],
            Evaluate[Sequence @@ FilterRules[{opts}, Options[Plot]]],
            PlotRange -> All,
            Filling -> Axis,
            Evaluate[AxesLabel -> {result["Parameters"][[plotIndex]], "PDF"}]
        ]
    ];

Options[posteriorMarginalPDFPlot1D] = Join[
    {
        "SmoothKernelDistributionOptions" -> {}
    },
    Options[Plot]
];

posteriorMarginalPDFDensityPlot2D[result_?AssociationQ, parameters : {_Symbol, _Symbol}, range_, opts : OptionsPattern[]] /;
    (ListQ[result["Parameters"]] && SubsetQ[result["Parameters"], parameters]):=
    posteriorMarginalPDFDensityPlot2D[
        result,
        Flatten[
            Position[
                result["Parameters"],
                Alternatives @@ parameters,
                {1},
                Length[parameters]
            ]
        ],
        range,
        opts
    ];

posteriorMarginalPDFDensityPlot2D[result_?AssociationQ, plotIndices : {_Integer, _Integer},
    range : (Automatic | {{_, _}, {_, _}}) : Automatic, opts : OptionsPattern[]
] /; (AllTrue[{"ParameterRanges", "EmpiricalPosteriorDistribution"}, KeyExistsQ[result, #]&] && Max[plotIndices] <= Length[result["ParameterRanges"]]):=
    Module[{
        x, y, pdf,
        plotRange = Replace[range, Automatic :> result["ParameterRanges"][[plotIndices]]]
    },
        pdf = PDF[
            KernelMixtureDistribution[
                WeightedData @@ MapAt[
                    Transpose,
                    Map[
                        MarginalDistribution[
                            result["EmpiricalPosteriorDistribution"],
                            plotIndices
                        ],
                        {"Domain", "Weights"}
                    ],
                    1
                ],
                Sequence @@ OptionValue["SmoothKernelDistributionOptions"]
            ],
            {x, y}
        ];
        DensityPlot[
            pdf,
            Evaluate[Flatten @ {x, plotRange[[1]]}],
            Evaluate[Flatten @ {y, plotRange[[2]]}],
            Evaluate[Sequence @@ FilterRules[{opts}, Options[DensityPlot]]],
            PlotLegends -> Automatic,
            Evaluate[PlotRange -> Join[plotRange, {All}]],
            Evaluate[FrameLabel -> result["Parameters"][[plotIndices]]]
        ]
    ];

Options[posteriorMarginalPDFDensityPlot2D] = Join[
    {
        "SmoothKernelDistributionOptions" -> {}
    },
    Options[DensityPlot]
];

posteriorMarginalCDFPlot1D[result_?AssociationQ, parameter_Symbol, opts : OptionsPattern[]] /; MemberQ[result["Parameters"], parameter] :=
    posteriorMarginalCDFPlot1D[result, First @ FirstPosition[result["Parameters"], parameter, Missing["Error"], {1}], opts];

posteriorMarginalCDFPlot1D[result_?AssociationQ, plotIndex_Integer, range : (Automatic | {_, _}) : Automatic, opts : OptionsPattern[]] /;
    (AllTrue[{"ParameterRanges", "EmpiricalPosteriorDistribution"}, KeyExistsQ[result, #]&] && plotIndex <= Length[result["ParameterRanges"]]) :=
    Module[{
        x, cdf,
        plotRange = Replace[range, Automatic :> result["ParameterRanges"][[plotIndex]]]
    },
        cdf = CDF[
            MarginalDistribution[
                result["EmpiricalPosteriorDistribution"],
                plotIndex
            ],
            x
        ];
        If[ MatchQ[cdf, Plus[Times[__]..]],
            ListStepPlot[
                Transpose[
                    MapAt[
                        Accumulate, 
                        Transpose[
                            SortBy[
                                {#[[2, 1, 1]], #[[1]]} & /@ List @@ cdf, 
                                First
                            ]
                        ],
                        2
                    ]
                ],
                Sequence @@ FilterRules[{opts}, Options[ListStepPlot]],
                PlotRange -> {0, 1},
                Filling -> Axis,
                AxesLabel -> {result["Parameters"][[plotIndex]], "CDF"}
            ],
            Plot[
                cdf,
                Evaluate[Flatten @ {x, plotRange}],
                Evaluate[Sequence @@ FilterRules[{opts}, Options[Plot]]],
                PlotRange -> {0, 1},
                Filling -> Axis,
                Evaluate[AxesLabel -> {result["Parameters"][[plotIndex]], "CDF"}]
            ]
        ]
    ];

Options[posteriorMarginalCDFPlot1D] = Join[
    {},
    Options[Plot]
];

posteriorMarginalCDFDensityPlot2D[result_?AssociationQ, parameters : {_Symbol, _Symbol},range_, opts : OptionsPattern[]] /;
    (ListQ[result["Parameters"]] && SubsetQ[result["Parameters"], parameters]):=
    posteriorMarginalCDFDensityPlot2D[
        result,
        Flatten[
            Position[
                result["Parameters"],
                Alternatives @@ parameters,
                {1},
                Length[parameters]
            ]
        ],
        range,
        opts
    ];


posteriorMarginalCDFDensityPlot2D[result_?AssociationQ, plotIndices : {_Integer, _Integer},
    range : (Automatic | {{_, _}, {_, _}}) : Automatic, opts : OptionsPattern[]
] /; (AllTrue[{"ParameterRanges", "EmpiricalPosteriorDistribution"}, KeyExistsQ[result, #]&] && Max[plotIndices] <= Length[result["ParameterRanges"]]):=
    Module[{
        x, y, cdf,
        plotRange = Replace[range, Automatic :> result["ParameterRanges"][[plotIndices]]]
    },
        cdf = CDF[
            MarginalDistribution[
                result["EmpiricalPosteriorDistribution"],
                plotIndices
            ],
            {x, y}
        ];
        ContourPlot[
            cdf,
            Evaluate[Flatten @ {x, plotRange[[1]]}],
            Evaluate[Flatten @ {y, plotRange[[2]]}],
            Evaluate[Sequence @@ FilterRules[{opts}, Options[DensityPlot]]],
            PlotLegends -> Automatic,
            Evaluate[PlotRange -> Join[plotRange, {0, 1}]],
            Evaluate[FrameLabel -> result["Parameters"][[plotIndices]]]
        ]
    ];

Options[posteriorMarginalCDFDensityPlot2D] = Join[
    {},
    Options[ContourPlot]
];


posteriorBubbleChart[result_?AssociationQ, parameters : {Repeated[_Symbol, {2, 3}]}, frac_, opts : OptionsPattern[]] /;
    (ListQ[result["Parameters"]] && SubsetQ[result["Parameters"], parameters]):=
    posteriorBubbleChart[
        result,
        Flatten[
            Position[
                result["Parameters"],
                Alternatives @@ parameters,
                {1},
                Length[parameters]
            ]
        ],
        frac,
        opts
    ];

posteriorBubbleChart[result_?AssociationQ, plotIndices : {Repeated[_Integer, {2, 3}]}, frac : _?NumericQ : 1, opts : OptionsPattern[]] /; 
    (KeyExistsQ[result, "Samples"] && Max[plotIndices] <= Length[result["Samples", 1, "Point"]] && Between[frac, {0, 1}]) :=
    Module[{
        data = Query[
            "Samples",
            Values,
            Flatten @ {#Point[[plotIndices]], #CrudePosteriorWeight}&
        ] @ takePosteriorFraction[result, frac],
        plotFunction,
        label
    },
        If[ Length[plotIndices] === 2,
            plotFunction = BubbleChart;
            label = FrameLabel
            ,
            plotFunction = BubbleChart3D;
            label = AxesLabel
        ];
        plotFunction[
            data,
            Sequence @@ FilterRules[{opts}, Options[plotFunction]],
            label -> result["Parameters"][[plotIndices]],
            ColorFunction -> Function[Opacity[0.7]]
        ]
    ];

Options[posteriorBubbleChart] = Join[
    {},
    DeleteDuplicatesBy[
        Join[
            Options[BubbleChart],
            Options[BubbleChart3D]
        ],
        First
    ]
];

gaussianProcessPredictionPlot[
    result_?(AssociationQ[#] && KeyExistsQ[#, "GaussianProcessData"]&),
    predictedDistributions : <|(_?NumericQ -> _) ..|>,
    opts : OptionsPattern[]
] :=
    Show[
        gaussianProcessPredictionPlot[
            predictedDistributions,
            opts,
            PlotLabel -> Style[StringForm[
                "Log evidence: `1` \[PlusMinus] `2`",
                Sequence @@ (
                    NumberForm[#, 4]& /@ Values[result["LogEvidence"]]
                )
            ], "Text"]
        ],
        Graphics[
            {
                Red,
                Point[
                    Transpose[
                        Values @ result[["GaussianProcessData", "OriginalData", {"Input", "Output"}]]
                    ]
                ]
            }
        ]
    ];

gaussianProcessPredictionPlot[predictedDistributions : <|(_?NumericQ -> _) ..|>, opts : OptionsPattern[]] := With[{
    DistributionPercentiles = Replace[
        OptionValue["DistributionPercentiles"],
        {
            "Moments" -> Function[
                Dot[
                    {
                        {1, -1,   1},
                        {1,  0,   0},
                        {1,  1,   1}
                    },
                    {Mean[#], StandardDeviation[#], Surd[CentralMoment[#, 3], 3]}
                ]
            ]
            ,
            levels : {__?NumericQ} /; (Min[levels] > 0 && Max[levels] < 1) :>
                Function[InverseCDF[#, levels]]
        }
    ]
},
    Module[{
        plotPoints = Map[
            DistributionPercentiles,
            KeySort[predictedDistributions]
        ]
    },
        ListPlot[
            plotPoints[[All, #]]& /@ Range[Length[First @ plotPoints]],
            Sequence @@ FilterRules[{opts}, Options[ListPlot]],
            Joined -> True
        ]
    ]
];
Options[gaussianProcessPredictionPlot] = Join[
    {
        "DistributionPercentiles" -> {0.05, 0.5, 0.95}
    },
    Options[ListPlot]
];



End[] (* End Private Context *)

EndPackage[]