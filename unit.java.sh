#!/bin/bash
echo ""
echo "import org.junit.Before;"
echo "import org.junit.BeforeClass;"
echo "import org.junit.Test;"
echo "import org.junit.runner.RunWith;"
echo "import org.mockito.Mockito;"
echo "import org.powermock.core.classloader.annotations.PrepareForTest;"
echo "import org.powermock.modules.junit4.PowerMockRunner;"
echo ""
echo "import static org.junit.Assert.*;"
echo "import static org.mockito.Matchers.*;"
echo "import static org.powermock.api.mockito.PowerMockito.*;"
echo ""
echo "@PrepareForTest({})"
echo "@RunWith(PowerMockRunner.class)"
echo "public class $1 {"
echo ""
echo "    @BeforeClass"
echo "    public static void _setup()"
echo "    {"
echo "    }"
echo ""
echo "    @Before"
echo "    public void setup()"
echo "    {"
echo "    }"
echo ""
echo "    @Test"
echo "    public void test()"
echo "    {"
echo "    }"
echo "}"
echo ""
